--[[
// Normalize all takes by filename to common gain and reduce 6db
// By Ryan McQuen (but really by @EricTBoneJackson)
//
// I find it useful for mixing to have a baseline
// and then adjusting the faders to taste to
// establish a balanced mix. I use -6db
// since it is usually a good target
// for rendering out if you are
// going to master the tracks
// or whatnot.
//
// v0.1.0 - 2021_12_02
// Initial release.
//
// v0.2.0 - 2021_12_03
// Re-normalize originally active take
// after loop.
//
// v0.3.0 - 2021_12_04
// Rewrite all behavior to target individual files
// inside of a track and normalize those
// against each other. Also, it is now
// in Lua.
]]--

local selectedMediaItems = {}
local takesForFilename = {}

reaper.SelectAllMediaItems(0, 1)

reaper.Undo_BeginBlock()

-- Save selected items and which take is active in each:
for i = 0, reaper.CountSelectedMediaItems() - 1 do
    local item = reaper.GetSelectedMediaItem(0, i)
    selectedMediaItems[item] = reaper.GetActiveTake(item)
end

-- Get every take of every selected item, grouped by filename:
for item in pairs(selectedMediaItems) do
    for t = 0, reaper.CountTakes(item) - 1 do
        local take = reaper.GetTake(item, t)
        if take then
            local source = reaper.GetMediaItemTake_Source(take)
            local filename = reaper.GetMediaSourceFileName(source)
            if not takesForFilename[filename] then
                takesForFilename[filename] = {}
            end
            takesForFilename[filename][take] = true
        end
    end
end

-- For each filename, select only media items containing it,
-- activate the correct take within each item,
-- then normalize them.
for filename, takelist in pairs(takesForFilename) do
    -- Deselect all items:
    reaper.Main_OnCommand(40289, 0)
    for take in pairs(takelist) do
        reaper.SetMediaItemSelected(reaper.GetMediaItemTake_Item(take), true)
        reaper.SetActiveTake(take)
    end
    -- Normalize to common gain:
    reaper.Main_OnCommand(40254, 0)
    for take in pairs(takelist) do
        local vol = reaper.GetMediaItemTakeInfo_Value(take, 'D_VOL')
        reaper.SetMediaItemTakeInfo_Value(take, 'D_VOL', vol / 2)
    end
end

-- Restore previously selected media items and their active takes:
for item, take in pairs(selectedMediaItems) do
    reaper.SetMediaItemSelected(item, true)
    reaper.SetActiveTake(take)
end

reaper.UpdateArrange()
reaper.Undo_EndBlock("Normalize all takes by filename to common gain and reduce 6db", 0)
