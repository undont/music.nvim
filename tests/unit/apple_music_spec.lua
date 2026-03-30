local apple_music = require("music.apple_music")

describe("apple_music", function()
    describe("_parse_output", function()
        it("parses standard output correctly", function()
            local output = "Song Name ||| Artist Name ||| Album Name ||| 240.5 ||| 30.2 ||| playing"
            local track = apple_music._parse_output(output)
            assert.is_not_nil(track)
            assert.equal("Song Name", track.name)
            assert.equal("Artist Name", track.artist)
            assert.equal("Album Name", track.album)
            assert.is_nil(track.art_url)
            assert.equal(math.floor(30.2 * 1000), track.progress_ms)
            assert.equal(math.floor(240.5 * 1000), track.duration_ms)
            assert.is_true(track.is_playing)
        end)

        it("returns nil for STOPPED output", function()
            assert.is_nil(apple_music._parse_output("STOPPED"))
        end)

        it("returns nil for STOPPED with trailing whitespace", function()
            assert.is_nil(apple_music._parse_output("STOPPED\n"))
        end)

        it("returns nil for empty string", function()
            assert.is_nil(apple_music._parse_output(""))
        end)

        it("returns nil for nil input", function()
            assert.is_nil(apple_music._parse_output(nil))
        end)

        it("returns nil when fewer than 6 parts", function()
            local output = "Song Name ||| Artist Name"
            assert.is_nil(apple_music._parse_output(output))
        end)

        it("converts duration from seconds to milliseconds", function()
            local output = "Song ||| Artist ||| Album ||| 240.5 ||| 0 ||| playing"
            local track = apple_music._parse_output(output)
            assert.equal(240500, track.duration_ms)
        end)

        it("converts position from seconds to milliseconds", function()
            local output = "Song ||| Artist ||| Album ||| 200 ||| 65.3 ||| playing"
            local track = apple_music._parse_output(output)
            assert.equal(math.floor(65.3 * 1000), track.progress_ms)
        end)

        it("identifies paused state", function()
            local output = "Song ||| Artist ||| Album ||| 200 ||| 10 ||| paused"
            local track = apple_music._parse_output(output)
            assert.is_false(track.is_playing)
        end)

        it("handles non-numeric duration gracefully", function()
            local output = "Song ||| Artist ||| Album ||| abc ||| 10 ||| playing"
            local track = apple_music._parse_output(output)
            assert.equal(0, track.duration_ms)
        end)

        it("handles non-numeric position gracefully", function()
            local output = "Song ||| Artist ||| Album ||| 200 ||| xyz ||| playing"
            local track = apple_music._parse_output(output)
            assert.equal(0, track.progress_ms)
        end)

        it("handles integer durations", function()
            local output = "Song ||| Artist ||| Album ||| 180 ||| 45 ||| playing"
            local track = apple_music._parse_output(output)
            assert.equal(180000, track.duration_ms)
            assert.equal(45000, track.progress_ms)
        end)

        it("handles output with trailing newline", function()
            local output = "Song ||| Artist ||| Album ||| 200 ||| 10 ||| playing\n"
            local track = apple_music._parse_output(output)
            assert.is_not_nil(track)
            assert.equal("Song", track.name)
        end)

        it("trims whitespace from parsed fields", function()
            local output = "  Song  ||| Artist  ||| Album  ||| 200 ||| 10 ||| playing"
            local track = apple_music._parse_output(output)
            assert.equal("Song", track.name)
            assert.equal("Artist", track.artist)
            assert.equal("Album", track.album)
        end)

        it("always sets art_url to nil", function()
            local output = "Song ||| Artist ||| Album ||| 200 ||| 10 ||| playing"
            local track = apple_music._parse_output(output)
            assert.is_nil(track.art_url)
        end)
    end)

    describe("interface", function()
        it("exposes get_now_playing", function()
            assert.is_function(apple_music.get_now_playing)
        end)

        it("exposes play", function()
            assert.is_function(apple_music.play)
        end)

        it("exposes pause", function()
            assert.is_function(apple_music.pause)
        end)

        it("exposes next_track", function()
            assert.is_function(apple_music.next_track)
        end)

        it("exposes prev_track", function()
            assert.is_function(apple_music.prev_track)
        end)

        it("exposes toggle_play", function()
            assert.is_function(apple_music.toggle_play)
        end)

        it("exposes extract_artwork", function()
            assert.is_function(apple_music.extract_artwork)
        end)

        it("exposes invalidate_cache as no-op", function()
            assert.is_function(apple_music.invalidate_cache)
            -- Should not error when called
            apple_music.invalidate_cache()
        end)
    end)
end)
