describe("spotify_local", function()
    local spotify_local

    before_each(function()
        package.loaded["music.spotify_local"] = nil
        spotify_local = require("music.spotify_local")
    end)

    describe("_parse_output", function()
        it("parses standard output correctly", function()
            local output =
                "My Song ||| My Artist ||| My Album ||| 210000 ||| 45.5 ||| playing ||| https://example.com/art.jpg"
            local result = spotify_local._parse_output(output)

            assert.equal("My Song", result.name)
            assert.equal("My Artist", result.artist)
            assert.equal("My Album", result.album)
            assert.equal(210000, result.duration_ms)
            assert.equal(45500, result.progress_ms)
            assert.is_true(result.is_playing)
            assert.equal("https://example.com/art.jpg", result.art_url)
        end)

        it("returns nil for STOPPED output", function()
            assert.is_nil(spotify_local._parse_output("STOPPED"))
        end)

        it("returns nil for STOPPED with trailing whitespace", function()
            assert.is_nil(spotify_local._parse_output("STOPPED  \n"))
        end)

        it("returns nil for empty string", function()
            assert.is_nil(spotify_local._parse_output(""))
        end)

        it("returns nil for nil input", function()
            assert.is_nil(spotify_local._parse_output(nil))
        end)

        it("returns nil when fewer than 7 parts", function()
            local output = "Song ||| Artist ||| Album ||| 210000 ||| 45 ||| playing"
            assert.is_nil(spotify_local._parse_output(output))
        end)

        it("converts position from seconds to milliseconds", function()
            local output = "Song ||| Artist ||| Album ||| 210000 ||| 30.0 ||| playing ||| https://example.com/art.jpg"
            local result = spotify_local._parse_output(output)
            assert.equal(30000, result.progress_ms)
        end)

        it("identifies paused state", function()
            local output = "Song ||| Artist ||| Album ||| 210000 ||| 30 ||| paused ||| https://example.com/art.jpg"
            local result = spotify_local._parse_output(output)
            assert.is_false(result.is_playing)
        end)

        it("handles missing value for art_url", function()
            local output = "Song ||| Artist ||| Album ||| 210000 ||| 30 ||| playing ||| missing value"
            local result = spotify_local._parse_output(output)
            assert.is_nil(result.art_url)
        end)

        it("handles non-numeric duration gracefully", function()
            local output = "Song ||| Artist ||| Album ||| abc ||| 30 ||| playing ||| https://example.com/art.jpg"
            local result = spotify_local._parse_output(output)
            assert.equal(0, result.duration_ms)
        end)

        it("handles non-numeric position gracefully", function()
            local output = "Song ||| Artist ||| Album ||| 210000 ||| abc ||| playing ||| https://example.com/art.jpg"
            local result = spotify_local._parse_output(output)
            assert.equal(0, result.progress_ms)
        end)

        it("handles output with trailing newline", function()
            local output = "Song ||| Artist ||| Album ||| 210000 ||| 30 ||| playing ||| https://example.com/art.jpg\n"
            local result = spotify_local._parse_output(output)
            assert.equal("Song", result.name)
        end)

        it("trims whitespace from parsed fields", function()
            local output =
                "  Song  ||| Artist  ||| Album  ||| 210000 ||| 30 ||| playing |||  https://example.com/art.jpg "
            local result = spotify_local._parse_output(output)
            assert.equal("Song", result.name)
            assert.equal("Artist", result.artist)
            assert.equal("Album", result.album)
        end)
    end)

    describe("interface", function()
        it("exposes get_now_playing", function()
            assert.is_function(spotify_local.get_now_playing)
        end)

        it("exposes play", function()
            assert.is_function(spotify_local.play)
        end)

        it("exposes pause", function()
            assert.is_function(spotify_local.pause)
        end)

        it("exposes next_track", function()
            assert.is_function(spotify_local.next_track)
        end)

        it("exposes prev_track", function()
            assert.is_function(spotify_local.prev_track)
        end)

        it("exposes toggle_play", function()
            assert.is_function(spotify_local.toggle_play)
        end)

        it("exposes extract_artwork as no-op", function()
            assert.is_function(spotify_local.extract_artwork)
        end)

        it("exposes invalidate_cache as no-op", function()
            assert.is_function(spotify_local.invalidate_cache)
        end)
    end)
end)
