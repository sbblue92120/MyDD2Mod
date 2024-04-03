local modname="MoreRandomChest"
local configfile=modname..".json"
log.info("["..modname.."]".."Start")
local myapi = require("_XYZApi/_XYZApi")
--settings
local _config={
    {name="ChanceScale",type="floatPercent",default=50},
    {name="ReplacedStaff",type="boolList",default={
                            --"Gm82_000",--��ʰȡ��Ʒ
                            --"Gm82_000_001",--��Ȼ���ɵ���Ʒ
                            --"Gm82_000_002",--��������Ʒ
                            ["Gm80_008"]="chain",--stone
                            ["Gm80_009"]="stone",--stone
                            ["Gm80_010"]="stone",--stone
                            ["Gm80_103"]="sandbag",--ɳ��
                            ["Gm80_109"]="tree",--tree
                            ["Gm80_110"]="tree",--tree?
                            ["Gm80_241"]="candle&glass?",
                            --["Gm82_001"]="key",
                            --["Gm82_002"]="key",
                            ["Gm82_009_01"]="plant gather point",--��
                            ["Gm82_009_02"]="plant gather point",
                            ["Gm82_009_03"]="plant gather point",
                            ["Gm82_009_04"]="plant gather point",--��
                            ["Gm82_009_05"]="plant gather point",--��
                            ["Gm82_009_06"]="plant gather point",--��
                            ["Gm82_009_10"]="plant gather point",--��
                            ["Gm82_009_20"]="plant gather point",--��
                            ["Gm82_016_10"]="bone gather point",--��ͷ
                            ["Gm82_017_10"]="wood gather point",--�����
                            ["Gm82_011"]="plant gather point",--��
                            ["Gm82_012"]="plant gather point",--��
                            ["Gm82_013"]="plant gather point",--��
                            ["Gm82_020"]="potato gather point",--��
                            ["Gm82_069"]="fish gather point",--��
                        --    "Gm80_079_10",--����
                        --    "Gm51_574",--����
                            ["Gm50_097"]="haystack",--���ݶ�
                            ["Gm50_011_00"]="wood",
                            ["Gm50_011_01"]="wood",
                            ["Gm50_011_02"]="wood",
                            ["Gm50_013_01"]="barrel",
                            ["Gm50_013_02"]="barrel",
                            ["Gm50_040_10"]="barrel",--ľͰ
                            ["Gm51_083"]="barrel",
                            ["Gm51_009"]="wood rack",
                            ["Gm51_010"]="wood rack",
                            ["Gm51_011"]="wood stick",
                        }
    },
}
local config=myapi.InitFromFile(_config,configfile)

local function Log(msg)
    log.info(modname..msg)
    print(msg)
end

local gimmickID2Name,gimmickName2ID=myapi.Enum2Map("app.GimmickID")

local function EnumListToInt2(list)
    local intList={}
    for v,rate in pairs(list) do
        local intvalue=gimmickName2ID[v]
        if intvalue~=nil and intvalue>=0 then
            intList[intvalue]=rate            
            print(intvalue,rate)
        end
    end
    return intList
end
local replaceList=EnumListToInt2({
    ["Gm80_001"]=32,--����
    ["Gm80_096"]=32,--����
    ["Gm80_097"]=32,--����
    ["Gm82_080"]=3,--�׳�
    ["Gm82_036"]=1,--̽����֤֮��
})


sdk.hook(
    sdk.find_type_definition("app.GenerateSelector"):get_method("randomSelect")
,    function (args)
        local this=sdk.to_managed_object(args[2])
        local t=this["<Table>k__BackingField"]
        if t~=nil and t._GimmickSetInfo ~=nil then
            local tableRow=t._GimmickSetInfo._BasicRowDatas
            local ct=tableRow:get_Count()-1
            for i=0,ct do
                local rowData=tableRow[i]
                local id=rowData._GimmickID
                --nil ��ʾ�����б��У�false��ʾû�й�ѡ
                if id~=nil and config.ReplacedStaff[gimmickID2Name[id]]~=nil and config.ReplacedStaff[gimmickID2Name[id]]~=false then
                    local roll=math.random(0,9999)/100.0
                    if roll < config.ChanceScale then
                        --will triggered for the same object when each time it's displayed
                        for replaceId,rate in pairs(replaceList) do
                            if roll<rate then
                                rowData._GimmickID=replaceId
                                print("Replace ",gimmickID2Name[id],roll,"Use",replaceId,rate*config.ChanceScale)
                                break
                            end
                            roll=roll-rate
                        end
                    end
                --else
                    --print("Ignore ",gimmickID2Name[id])
                end
            end
        end
end,nil
)

--�¼ӵ������ǿյģ����һ��Ĭ�ϵ���
local itemIds={}
function Init()
    itemIds={}
    local im=sdk.get_managed_singleton("app.ItemManager")
    --����ֱ�Ӵ�app.ItemIDEnumȡID,����������invalid��Ʒ
    local iter=im._ItemDataDict:GetEnumerator()
    iter:MoveNext()
    while iter:get_Current():get_Value()~=nil do
        local itemCommonParam=iter:get_Current():get_Value()
        local name=itemCommonParam:get_Name()
        if name ~="Invalid" and name~=nil then
            if itemCommonParam._SubCategory==nil or (itemCommonParam._SubCategory ~= CategoryQuest) then
                table.insert(itemIds,itemCommonParam._Id)
            end
        end
        iter:MoveNext()
    end
    Log("Init Items")
end
sdk.hook(sdk.find_type_definition("app.GuiManager"):get_method("OnChangeSceneType"),nil,Init)

--������80_001,80_096,80_097�ȣ���ʹ��app.gm80_001(ʹ��app.gm80_001�Ķ������ӣ�ʹ��app.gm82_009�Ķ��ǲɼ���)
sdk.hook(
    sdk.find_type_definition("app.gm80_001"):get_method("getItem"),
    function(args)
        local this=sdk.to_managed_object(args[2])
        --app.gm80_001.ItemParam
        local ItemList=this.ItemList
        if ItemList~=nil and ItemList:get_Count()==0 then
            print("Generate Random Drop")
            local myItem=sdk.create_instance("app.gm80_001.ItemParam"):add_ref()
            myItem.ItemId=itemIds[math.random(1,#itemIds)]
            myItem.ItemNum=1
            ItemList:Add(myItem)
        end
    end,nil
)

myapi.DrawIt(modname,configfile,_config,config,nil)