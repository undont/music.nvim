local utils = require("music.utils")

describe("utils", function()
    describe("fmt_time", function()
        it("formats zero as 0:00", function()
            assert.equal("0:00", utils.fmt_time(0))
        end)

        it("formats exact seconds correctly", function()
            assert.equal("0:30", utils.fmt_time(30000))
        end)

        it("pads single-digit seconds with leading zero", function()
            assert.equal("1:03", utils.fmt_time(63000))
        end)

        it("formats exact minutes", function()
            assert.equal("3:00", utils.fmt_time(180000))
        end)

        it("handles large durations", function()
            assert.equal("61:01", utils.fmt_time(3661000))
        end)

        it("truncates sub-second precision", function()
            assert.equal("0:01", utils.fmt_time(1999))
        end)

        it("handles one millisecond", function()
            assert.equal("0:00", utils.fmt_time(1))
        end)

        it("handles typical track duration", function()
            assert.equal("3:45", utils.fmt_time(225000))
        end)
    end)

    describe("clean_name", function()
        it("leaves plain names untouched", function()
            assert.equal("Normal Song", utils.clean_name("Normal Song"))
        end)

        it("removes (feat. Artist)", function()
            assert.equal("Song", utils.clean_name("Song (feat. Other Artist)"))
        end)

        it("removes (feat Artist) without period", function()
            assert.equal("Song", utils.clean_name("Song (feat Other Artist)"))
        end)

        it("removes [feat. Artist]", function()
            assert.equal("Song", utils.clean_name("Song [feat. Other Artist]"))
        end)

        it("removes [feat Artist] without period", function()
            assert.equal("Song", utils.clean_name("Song [feat Other Artist]"))
        end)

        it("removes (with Artist)", function()
            assert.equal("Song", utils.clean_name("Song (with Other Artist)"))
        end)

        it("handles multiple feat patterns", function()
            assert.equal("Song", utils.clean_name("Song (feat. A) [feat. B]"))
        end)

        it("trims surrounding whitespace", function()
            assert.equal("Song", utils.clean_name("  Song  "))
        end)

        it("handles empty string after removal", function()
            -- Edge case: name is entirely a feat tag
            assert.equal("", utils.clean_name("(feat. Artist)"))
        end)

        it("preserves parentheses that are not feat/with", function()
            assert.equal("Song (Remix)", utils.clean_name("Song (Remix)"))
        end)

        it("preserves brackets that are not feat", function()
            assert.equal("Song [Deluxe]", utils.clean_name("Song [Deluxe]"))
        end)
    end)

    describe("trim_artist", function()
        it("returns short artist names unchanged", function()
            assert.equal("Short", utils.trim_artist("Short", 20))
        end)

        it("returns artist at exact max length unchanged", function()
            assert.equal("12345", utils.trim_artist("12345", 5))
        end)

        it("truncates long artist names with ellipsis", function()
            assert.equal("Very Long Ar...", utils.trim_artist("Very Long Artist Name", 15))
        end)

        it("handles max_len shorter than ellipsis gracefully", function()
            -- With max_len=3, we get sub(1,0) .. '...' = '...'
            assert.equal("...", utils.trim_artist("Long Name", 3))
        end)

        it("handles single character max_len", function()
            local result = utils.trim_artist("Long Name", 1)
            assert.is_string(result)
        end)
    end)
end)
