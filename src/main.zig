const std = @import("std");
const spider = @import("spider");
const bands = @import("models/bands.zig");

const db = spider.pg;

pub fn main(init: std.process.Init) !void {
    const arena: std.mem.Allocator = init.arena.allocator();
    const io = init.io;

    spider.loadEnv(arena, ".env") catch {};
    try db.init(arena, io, .{});
    defer db.deinit();

    try initDb(arena);

    var app = try spider.Spider.init(arena, io, "0.0.0.0", 8080, .{});
    defer app.deinit();

    app
        .get("/", rootHandler)
        .get("/bands", getBands)
        .get("/bands/:id", getBand)
        .post("/bands", createBand)
        .delete("/bands/:id", deleteBand)
        .listen() catch |err| return err;
}

fn getBands(arena: std.mem.Allocator, _: *spider.Request) !spider.Response {
    const all_bands = try db.query(bands.Band, arena, "SELECT id, name, city, genre, formed_year FROM bands ORDER BY id", .{});
    return spider.Response.json(arena, all_bands);
}

fn getBand(arena: std.mem.Allocator, req: *spider.Request) !spider.Response {
    const id_str = req.params.get("id") orelse return error.NotFound;
    const band_id = std.fmt.parseInt(i64, id_str, 10) catch return error.InvalidId;

    const result = try db.query(bands.Band, arena, "SELECT id, name, city, genre, formed_year FROM bands WHERE id = $1", .{ .id = band_id });

    if (result.len > 0) {
        return spider.Response.json(arena, result[0]);
    }

    return spider.Response.json(arena, .{ .message = "Band not found" });
}

fn createBand(arena: std.mem.Allocator, req: *spider.Request) !spider.Response {
    const body = try req.bindJson(arena, bands.BandInput);

    const new_result = try db.query(struct { id: i64 }, arena, "INSERT INTO bands (name, city, genre, formed_year) VALUES ($1, $2, $3, $4) RETURNING id", .{
        .name = body.name,
        .city = body.city,
        .genre = body.genre,
        .formed_year = body.formed_year,
    });

    return spider.Response.json(arena, .{ .id = new_result[0].id, .name = body.name });
}

fn deleteBand(arena: std.mem.Allocator, req: *spider.Request) !spider.Response {
    const id_str = req.params.get("id") orelse return error.NotFound;
    const band_id = std.fmt.parseInt(i64, id_str, 10) catch return error.InvalidId;

    try db.query(void, arena, "DELETE FROM bands WHERE id = $1", .{ .id = band_id });
    return spider.Response.json(arena, .{ .deleted = true });
}

fn rootHandler(arena: std.mem.Allocator, _: *spider.Request) !spider.Response {
    return spider.Response.json(arena, .{
        .message = "Bandas de Metal Brasileiro API",
        .endpoints = .{
            .get_bands = "GET /bands",
            .get_band = "GET /bands/:id",
            .create_band = "POST /bands",
            .delete_band = "DELETE /bands/:id",
        },
    });
}

fn initDb(allocator: std.mem.Allocator) !void {
    var arena = std.heap.ArenaAllocator.init(allocator);
    defer arena.deinit();

    _ = try db.query(void, arena.allocator(),
        \\CREATE TABLE IF NOT EXISTS bands (id BIGSERIAL PRIMARY KEY, name TEXT NOT NULL, city TEXT NOT NULL, genre TEXT NOT NULL, formed_year INTEGER NOT NULL)
    , .{});

    const result = try db.query(struct { count: i64 }, arena.allocator(), "SELECT COUNT(*) as count FROM bands", .{});
    const count = if (result.len > 0) result[0].count else 0;

    if (count == 0) {
        const bands_data = [_]bands.BandInput{
            .{ .name = "Eternal Rest", .city = "Feira de Santana", .genre = "Thrash Metal", .formed_year = 2005 },
            .{ .name = "Mortal", .city = "Salvador", .genre = "Death Metal", .formed_year = 1998 },
            .{ .name = "Krisiun", .city = "Feira de Santana", .genre = "Death Metal", .formed_year = 1990 },
            .{ .name = "Satanic", .city = "Salvador", .genre = "Black Metal", .formed_year = 1995 },
            .{ .name = "Marduk", .city = "Salvador", .genre = "Black Metal", .formed_year = 1992 },
            .{ .name = "Hypnose", .city = "São Paulo", .genre = "Death Metal", .formed_year = 1995 },
            .{ .name = "Orchid", .city = "Feira de Santana", .genre = "Death Metal", .formed_year = 2000 },
            .{ .name = "Crisálida", .city = "Salvador", .genre = "Death Metal", .formed_year = 1996 },
            .{ .name = "Sepultura", .city = "Belo Horizonte", .genre = "Thrash Metal", .formed_year = 1984 },
            .{ .name = "Angel Dust", .city = "São Paulo", .genre = "Thrash Metal", .formed_year = 1985 },
            .{ .name = "Vulcano", .city = "Belém", .genre = "Thrash Metal", .formed_year = 1987 },
            .{ .name = "Sarcofago", .city = "Belo Horizonte", .genre = "Death Metal", .formed_year = 1985 },
            .{ .name = "Mutilated", .city = "Belo Horizonte", .genre = "Death Metal", .formed_year = 1989 },
            .{ .name = "Incidental", .city = "Rio de Janeiro", .genre = "Grindcore", .formed_year = 1992 },
            .{ .name = "Purgatorio", .city = "Salvador", .genre = "Black Metal", .formed_year = 1998 },
            .{ .name = "Temple of Damnation", .city = "Feira de Santana", .genre = "Black Metal", .formed_year = 1999 },
            .{ .name = "Alastor", .city = "São Paulo", .genre = "Black Metal", .formed_year = 1996 },
            .{ .name = "Void", .city = "Rio de Janeiro", .genre = "Death Metal", .formed_year = 1991 },
            .{ .name = "Rot", .city = "Salvador", .genre = "Death Metal", .formed_year = 1997 },
            .{ .name = "Cruciamentum", .city = "Feira de Santana", .genre = "Death Metal", .formed_year = 2001 },
            .{ .name = "Gorgone", .city = "Salvador", .genre = "Black Metal", .formed_year = 2000 },
            .{ .name = "Baalho", .city = "Recife", .genre = "Death Metal", .formed_year = 1994 },
            .{ .name = " Witchfall", .city = "Feira de Santana", .genre = "Black Metal", .formed_year = 2002 },
            .{ .name = "Despised", .city = "Salvador", .genre = "Death Metal", .formed_year = 1999 },
            .{ .name = "Imprecation", .city = "São Paulo", .genre = "Black Metal", .formed_year = 1993 },
            .{ .name = "Souls", .city = "Feira de Santana", .genre = "Death Metal", .formed_year = 1998 },
            .{ .name = "Haematipsis", .city = "Salvador", .genre = "Death Metal", .formed_year = 2000 },
            .{ .name = "Botulism", .city = "São Paulo", .genre = "Grindcore", .formed_year = 1995 },
            .{ .name = "Frenétiko", .city = "Rio de Janeiro", .genre = "Grindcore", .formed_year = 1991 },
            .{ .name = "Causa Mortis", .city = "São Paulo", .genre = "Death Metal", .formed_year = 1994 },
            .{ .name = "Executive", .city = "Salvador", .genre = "Thrash Metal", .formed_year = 1997 },
            .{ .name = "Nível Violência", .city = "São Paulo", .genre = "Thrash Metal", .formed_year = 1986 },
            .{ .name = "Ratos de Porão", .city = "Rio de Janeiro", .genre = "Death Metal", .formed_year = 1986 },
            .{ .name = "Olho Seco", .city = "São Paulo", .genre = "Thrash Metal", .formed_year = 1985 },
            .{ .name = "Cólera", .city = "São Paulo", .genre = "Thrash Metal", .formed_year = 1984 },
            .{ .name = "Glória", .city = "Salvador", .genre = "Thrash Metal", .formed_year = 1998 },
            .{ .name = "Loudness", .city = "São Paulo", .genre = "Thrash Metal", .formed_year = 1985 },
            .{ .name = "Panacea", .city = "Feira de Santana", .genre = "Death Metal", .formed_year = 2003 },
            .{ .name = "Profane", .city = "Salvador", .genre = "Death Metal", .formed_year = 2001 },
            .{ .name = "Obscene", .city = "São Paulo", .genre = "Death Metal", .formed_year = 1999 },
            .{ .name = "Abyss", .city = "Feira de Santana", .genre = "Death Metal", .formed_year = 2000 },
            .{ .name = "Funeral", .city = "Salvador", .genre = "Death Metal", .formed_year = 1998 },
            .{ .name = "Peste", .city = "Belo Horizonte", .genre = "Death Metal", .formed_year = 1995 },
            .{ .name = "Escrotor", .city = "Salvador", .genre = "Grindcore", .formed_year = 1996 },
            .{ .name = "Massacration", .city = "Feira de Santana", .genre = "Death Metal", .formed_year = 1999 },
            .{ .name = "Derhex", .city = "Salvador", .genre = "Death Metal", .formed_year = 2002 },
            .{ .name = "Terror 2000", .city = "São Paulo", .genre = "Grindcore", .formed_year = 1994 },
            .{ .name = "Utakk", .city = "Salvador", .genre = "Death Metal", .formed_year = 2001 },
            .{ .name = "Diablo", .city = "Feira de Santana", .genre = "Thrash Metal", .formed_year = 1997 },
            .{ .name = "Atomic", .city = "Salvador", .genre = "Thrash Metal", .formed_year = 1998 },
        };

        for (bands_data) |band| {
            _ = try db.query(void, arena.allocator(), "INSERT INTO bands (name, city, genre, formed_year) VALUES ($1, $2, $3, $4)", .{
                .name = band.name,
                .city = band.city,
                .genre = band.genre,
                .formed_year = band.formed_year,
            });
        }

        std.log.info("Inserted {} bands", .{bands_data.len});
    }
}
