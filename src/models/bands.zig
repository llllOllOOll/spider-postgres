const std = @import("std");

pub const Band = struct {
    id: i64 = 0,
    name: []const u8,
    city: []const u8,
    genre: []const u8,
    formed_year: i32,
};

pub const BandInput = struct {
    name: []const u8,
    city: []const u8,
    genre: []const u8,
    formed_year: i32,
};

pub const BandResponse = struct {
    id: i64,
    name: []const u8,
    city: []const u8,
    genre: []const u8,
    formed_year: i32,
};
