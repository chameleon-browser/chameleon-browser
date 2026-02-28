// Copyright (C) 2023-2026  Lightpanda (Selecy SAS)
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as
// published by the Free Software Foundation, either version 3 of the
// License, or (at your option) any later version.
//
// Minimal PNG encoder for canvas toDataURL().
// Generates valid PNG images from raw RGBA pixel data using uncompressed
// (stored) zlib blocks. This avoids the need for a full deflate compressor
// while producing spec-compliant PNG output.

const std = @import("std");

const base64_alphabet = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

/// Encode RGBA pixel data as a PNG data URL string.
/// Returns "data:image/png;base64,..." allocated from the given arena.
pub fn encodeDataURL(arena: std.mem.Allocator, rgba: []const u8, width: u32, height: u32) ![]const u8 {
    const png_data = try encodePNG(arena, rgba, width, height);
    const b64_len = ((png_data.len + 2) / 3) * 4;
    const prefix = "data:image/png;base64,";
    const result = try arena.alloc(u8, prefix.len + b64_len);
    @memcpy(result[0..prefix.len], prefix);
    base64Encode(result[prefix.len..], png_data);
    return result;
}

/// Encode raw RGBA data into a valid PNG byte sequence.
fn encodePNG(arena: std.mem.Allocator, rgba: []const u8, width: u32, height: u32) ![]const u8 {
    // Calculate sizes
    // Each row: 1 filter byte + width * 4 RGBA bytes
    const row_size: usize = 1 + @as(usize, width) * 4;
    const raw_size: usize = row_size * @as(usize, height);

    // Zlib stored blocks: each block max 65535 bytes
    // Block header: 5 bytes (1 byte BFINAL+BTYPE, 2 bytes LEN, 2 bytes NLEN)
    const max_block: usize = 65535;
    const num_blocks = if (raw_size == 0) 1 else (raw_size + max_block - 1) / max_block;
    // zlib header (2) + blocks * 5 + raw_data + adler32 (4)
    const zlib_size: usize = 2 + num_blocks * 5 + raw_size + 4;

    // PNG: signature(8) + IHDR(25) + IDAT(12+zlib_size) + IEND(12)
    const png_size: usize = 8 + 25 + 12 + zlib_size + 12;

    const buf = try arena.alloc(u8, png_size);
    var pos: usize = 0;

    // PNG signature
    @memcpy(buf[pos..][0..8], &[_]u8{ 0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A });
    pos += 8;

    // IHDR chunk
    pos = writeChunk(buf, pos, "IHDR", &ihdrData(width, height));

    // IDAT chunk - build zlib stream with stored (uncompressed) blocks
    const idat_data = try arena.alloc(u8, zlib_size);
    var zpos: usize = 0;

    // Zlib header: CMF=0x78 (deflate, window=32K), FLG=0x01 (no dict, FCHECK=1)
    idat_data[zpos] = 0x78;
    zpos += 1;
    idat_data[zpos] = 0x01;
    zpos += 1;

    // Prepare raw image data with filter bytes
    const raw_data = try arena.alloc(u8, raw_size);
    for (0..height) |y| {
        const row_start = y * row_size;
        raw_data[row_start] = 0; // filter: None
        const src_start = y * @as(usize, width) * 4;
        const src_end = src_start + @as(usize, width) * 4;
        @memcpy(raw_data[row_start + 1 .. row_start + row_size], rgba[src_start..src_end]);
    }

    // Write stored blocks
    var remaining = raw_size;
    var data_offset: usize = 0;
    while (remaining > 0 or data_offset == 0) {
        const block_len = @min(remaining, max_block);
        const is_last: u8 = if (remaining <= max_block) 1 else 0;
        idat_data[zpos] = is_last; // BFINAL=is_last, BTYPE=00 (stored)
        zpos += 1;
        // LEN (little-endian)
        idat_data[zpos] = @intCast(block_len & 0xFF);
        zpos += 1;
        idat_data[zpos] = @intCast((block_len >> 8) & 0xFF);
        zpos += 1;
        // NLEN (one's complement of LEN)
        const nlen = ~@as(u16, @intCast(block_len));
        idat_data[zpos] = @intCast(nlen & 0xFF);
        zpos += 1;
        idat_data[zpos] = @intCast((nlen >> 8) & 0xFF);
        zpos += 1;
        // Block data
        if (block_len > 0) {
            @memcpy(idat_data[zpos .. zpos + block_len], raw_data[data_offset .. data_offset + block_len]);
            zpos += block_len;
        }
        data_offset += block_len;
        remaining -= block_len;
        if (block_len == 0) break;
    }

    // Adler-32 checksum (big-endian)
    const adler = adler32(raw_data);
    idat_data[zpos] = @intCast((adler >> 24) & 0xFF);
    zpos += 1;
    idat_data[zpos] = @intCast((adler >> 16) & 0xFF);
    zpos += 1;
    idat_data[zpos] = @intCast((adler >> 8) & 0xFF);
    zpos += 1;
    idat_data[zpos] = @intCast(adler & 0xFF);
    zpos += 1;

    pos = writeChunk(buf, pos, "IDAT", idat_data[0..zpos]);

    // IEND chunk
    pos = writeChunk(buf, pos, "IEND", &.{});

    return buf[0..pos];
}

fn ihdrData(width: u32, height: u32) [13]u8 {
    var data: [13]u8 = undefined;
    // Width (big-endian)
    data[0] = @intCast((width >> 24) & 0xFF);
    data[1] = @intCast((width >> 16) & 0xFF);
    data[2] = @intCast((width >> 8) & 0xFF);
    data[3] = @intCast(width & 0xFF);
    // Height (big-endian)
    data[4] = @intCast((height >> 24) & 0xFF);
    data[5] = @intCast((height >> 16) & 0xFF);
    data[6] = @intCast((height >> 8) & 0xFF);
    data[7] = @intCast(height & 0xFF);
    data[8] = 8; // bit depth
    data[9] = 6; // color type: RGBA
    data[10] = 0; // compression method
    data[11] = 0; // filter method
    data[12] = 0; // interlace method
    return data;
}

fn writeChunk(buf: []u8, start: usize, chunk_type: *const [4]u8, data: []const u8) usize {
    var pos = start;
    const len: u32 = @intCast(data.len);

    // Length (big-endian)
    buf[pos] = @intCast((len >> 24) & 0xFF);
    pos += 1;
    buf[pos] = @intCast((len >> 16) & 0xFF);
    pos += 1;
    buf[pos] = @intCast((len >> 8) & 0xFF);
    pos += 1;
    buf[pos] = @intCast(len & 0xFF);
    pos += 1;

    // Type
    @memcpy(buf[pos..][0..4], chunk_type);
    pos += 4;

    // Data
    if (data.len > 0) {
        @memcpy(buf[pos .. pos + data.len], data);
        pos += data.len;
    }

    // CRC32 over type + data
    const crc_data_len = 4 + data.len;
    const crc = crc32(buf[start + 4 .. start + 4 + crc_data_len]);
    buf[pos] = @intCast((crc >> 24) & 0xFF);
    pos += 1;
    buf[pos] = @intCast((crc >> 16) & 0xFF);
    pos += 1;
    buf[pos] = @intCast((crc >> 8) & 0xFF);
    pos += 1;
    buf[pos] = @intCast(crc & 0xFF);
    pos += 1;

    return pos;
}

fn adler32(data: []const u8) u32 {
    const MOD_ADLER: u32 = 65521;
    var a: u32 = 1;
    var b: u32 = 0;
    for (data) |byte| {
        a = (a + byte) % MOD_ADLER;
        b = (b + a) % MOD_ADLER;
    }
    return (b << 16) | a;
}

/// CRC32 lookup table for PNG (polynomial 0xEDB88320)
const crc_table: [256]u32 = blk: {
    @setEvalBranchQuota(10000);
    var table: [256]u32 = undefined;
    for (0..256) |n| {
        var c: u32 = @intCast(n);
        for (0..8) |_| {
            if (c & 1 != 0) {
                c = 0xEDB88320 ^ (c >> 1);
            } else {
                c = c >> 1;
            }
        }
        table[n] = c;
    }
    break :blk table;
};

fn crc32(data: []const u8) u32 {
    var crc: u32 = 0xFFFFFFFF;
    for (data) |byte| {
        crc = crc_table[(crc ^ byte) & 0xFF] ^ (crc >> 8);
    }
    return crc ^ 0xFFFFFFFF;
}

fn base64Encode(dest: []u8, source: []const u8) void {
    var di: usize = 0;
    var si: usize = 0;
    const full_chunks = source.len / 3;
    for (0..full_chunks) |_| {
        const b0 = source[si];
        const b1 = source[si + 1];
        const b2 = source[si + 2];
        dest[di] = base64_alphabet[b0 >> 2];
        dest[di + 1] = base64_alphabet[((b0 & 0x03) << 4) | (b1 >> 4)];
        dest[di + 2] = base64_alphabet[((b1 & 0x0F) << 2) | (b2 >> 6)];
        dest[di + 3] = base64_alphabet[b2 & 0x3F];
        di += 4;
        si += 3;
    }
    const remaining = source.len - si;
    if (remaining == 1) {
        dest[di] = base64_alphabet[source[si] >> 2];
        dest[di + 1] = base64_alphabet[(source[si] & 0x03) << 4];
        dest[di + 2] = '=';
        dest[di + 3] = '=';
    } else if (remaining == 2) {
        dest[di] = base64_alphabet[source[si] >> 2];
        dest[di + 1] = base64_alphabet[((source[si] & 0x03) << 4) | (source[si + 1] >> 4)];
        dest[di + 2] = base64_alphabet[(source[si + 1] & 0x0F) << 2];
        dest[di + 3] = '=';
    }
}
