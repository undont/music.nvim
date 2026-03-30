local spotify = require("music.spotify")

describe("spotify", function()
    describe("_parse", function()
        it("parses a standard track with one artist", function()
            local data = {
                is_playing = true,
                progress_ms = 30000,
                item = {
                    name = "Song Title",
                    duration_ms = 200000,
                    artists = { { name = "Artist A" } },
                    album = {
                        name = "Album Name",
                        images = { { url = "https://example.com/art.jpg" } },
                    },
                },
            }
            local track = spotify._parse(data)
            assert.equal("Song Title", track.name)
            assert.equal("Artist A", track.artist)
            assert.equal("Album Name", track.album)
            assert.equal("https://example.com/art.jpg", track.art_url)
            assert.equal(30000, track.progress_ms)
            assert.equal(200000, track.duration_ms)
            assert.is_true(track.is_playing)
        end)

        it("joins multiple artists with comma", function()
            local data = {
                is_playing = false,
                progress_ms = 0,
                item = {
                    name = "Collab Track",
                    duration_ms = 180000,
                    artists = {
                        { name = "Artist A" },
                        { name = "Artist B" },
                        { name = "Artist C" },
                    },
                    album = {
                        name = "Album",
                        images = { { url = "https://example.com/art.jpg" } },
                    },
                },
            }
            local track = spotify._parse(data)
            assert.equal("Artist A, Artist B, Artist C", track.artist)
        end)

        it("returns nil art_url when images list is empty", function()
            local data = {
                is_playing = false,
                progress_ms = 0,
                item = {
                    name = "Song",
                    duration_ms = 100000,
                    artists = { { name = "Artist" } },
                    album = { name = "Album", images = {} },
                },
            }
            local track = spotify._parse(data)
            assert.is_nil(track.art_url)
        end)

        it("handles missing progress_ms gracefully", function()
            local data = {
                is_playing = true,
                item = {
                    name = "Song",
                    duration_ms = 100000,
                    artists = { { name = "Artist" } },
                    album = { name = "Album", images = { { url = "http://art.jpg" } } },
                },
            }
            local track = spotify._parse(data)
            assert.equal(0, track.progress_ms)
        end)

        it("handles missing duration_ms gracefully", function()
            local data = {
                is_playing = true,
                progress_ms = 5000,
                item = {
                    name = "Song",
                    artists = { { name = "Artist" } },
                    album = { name = "Album", images = { { url = "http://art.jpg" } } },
                },
            }
            local track = spotify._parse(data)
            assert.equal(0, track.duration_ms)
        end)

        it("correctly reports paused state", function()
            local data = {
                is_playing = false,
                progress_ms = 60000,
                item = {
                    name = "Paused Song",
                    duration_ms = 300000,
                    artists = { { name = "Artist" } },
                    album = { name = "Album", images = { { url = "http://art.jpg" } } },
                },
            }
            local track = spotify._parse(data)
            assert.is_false(track.is_playing)
        end)

        it("picks first image when multiple are available", function()
            local data = {
                is_playing = true,
                progress_ms = 0,
                item = {
                    name = "Song",
                    duration_ms = 100000,
                    artists = { { name = "Artist" } },
                    album = {
                        name = "Album",
                        images = {
                            { url = "https://large.jpg" },
                            { url = "https://medium.jpg" },
                            { url = "https://small.jpg" },
                        },
                    },
                },
            }
            local track = spotify._parse(data)
            assert.equal("https://large.jpg", track.art_url)
        end)
    end)
end)
