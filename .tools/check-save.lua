package.path="./?.lua;"..package.path
local cfg=require "config";cfg.save_dir=".tools/"
local paths={".tools/rally-save-0.dat",".tools/rally-save-1.dat"}
for _,path in ipairs(paths) do os.remove(path) end
package.loaded.save=nil
local S=require "save"
assert(not S.canContinue() and S.wins()==0)
assert(S.newGame())
assert(S.record(1,3));assert(not S.canContinue())
assert(S.record(1,1));assert(S.canContinue() and S.wins()==1)
assert(S.record(1,1));assert(S.wins()==1,"same track cannot win championship twice")
package.loaded.save=nil;S=require "save";assert(S.canContinue() and S.ranks[1]==1,"real file survives module reload")
assert(S.record(2,1));assert(S.wins()==2)
local seq=S.sequence
local f=assert(io.open(paths[seq%2+1],"wb"));f:write("CORRUPTED");f:close()
package.loaded.save=nil;S=require "save";assert(S.canContinue() and S.wins()==1,"corrupt newest slot must fall back to previous valid save")
assert(S.newGame());assert(not S.canContinue())
package.loaded.save=nil;S=require "save";assert(not S.canContinue(),"new game must clear persisted victories")
local old=io.open;io.open=function() return nil,"read only" end
assert(not S.record(3,1) and S.status=="SAVE INDISPONIVEL");io.open=old
for _,path in ipairs(paths) do os.remove(path) end
print("PASS: real-file persistence, Continue unlock, distinct-track championship, best rank, restart loading, journal corruption recovery, new-game clear and read-only failure")
