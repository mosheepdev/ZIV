var Util = {};

Util.SecondsToHHMMSS = (function (d) {
	d = Number(d);
	var h = Math.floor(d / 3600);
	var m = Math.floor(d % 3600 / 60);
	var s = Math.floor(d % 3600 % 60);
	return ((h > 0 ? h + ":" + (m < 10 ? "0" : "") : "") + m + ":" + (s < 10 ? "0" : "") + s); 
});

Util.GetSteamID32 = (function () {
    var playerInfo = Game.GetPlayerInfo(Game.GetLocalPlayerID());

    var steamID64 = playerInfo.player_steamid,
        steamIDPart = Number(steamID64.substring(3)),
        steamID32 = String(steamIDPart - 61197960265728);

    return steamID32;
});

Util.GetDate = (function () {
    var today = new Date();
    var dd = today.getDate();
    var mm = today.getMonth()+1; //January is 0!
    var yyyy = today.getFullYear();

    return yyyy * 10000 + mm * 100 + dd;
});

Util.RoundToTwo = (function (num) {    
    return +(Math.round(num + "e+2")  + "e-2");
});

Util.RoundToThree = (function (num) {    
    return +(Math.round(num + "e+3")  + "e-3");
});

Util.RepeatNumber = (function (num, length) {    
    return num - Math.floor(num / length) * length;
});

Util.AutoUppercase = (function (str) {
    return str.replace(/\w\S*/g, function(txt){return txt.charAt(0).toUpperCase() + txt.substr(1).toLowerCase();});
});

Util.SpanString = (function (str, className) {
    if (!str) return str;
    return "<span class=\"" + className + "\">" + str + "</span>";
});

Util.ColorString = (function (str, color) {
    return "<font color=\"" + (color || "#FFFFFF") + "\">" + str + "</font>";
});

Util.RuneToItem = (function (modifier) {
    var hero = Players.GetPlayerHeroEntityIndex( Players.GetLocalPlayer() );
    var heroName = PlayerTables.GetTableValue("kvs", "heroes")[Entities.GetUnitName(hero)]["SecondName"];

    var item = PlayerTables.GetTableValue("kvs", "items")[modifier.replace("ziv_" + heroName, "item_rune")];
    if (!item) {
        item = PlayerTables.GetTableValue("kvs", "items")[modifier.replace("ziv", "item_rune")];
    }

    return item;
});

// https://github.com/TideSofDarK/ZiV/wiki/Rune-Tooltip-Formatting
// Default is modifyMethod == "Multiply" and modifierType == "Percent"

Util.ConvertValue = (function (modifier, originalValue, modifierValue, dontModify) {
    var itemKV = Util.RuneToItem(modifier);

    if (!itemKV) {
        return modifierValue;
    }

    var tooltipType     = itemKV["Tooltip"];
    var modifierType    = itemKV["Type"];
    var modifyMethod    = itemKV["Method"];
    var multiplier      = itemKV["Reduction"] ? -1 : 1;

    if (dontModify) {
        originalValue = modifyMethod == "Multiply" || !modifyMethod ? 1 : 0;
    }

    var newValue = originalValue;
    if (modifierType == "Bool") {
        return "";
    } else if ((!modifyMethod || modifyMethod == "Multiply") && (!modifierType || modifierType == "Percent") && !dontModify) {
        newValue = originalValue * (1 + (modifierValue / 100 * multiplier));
    } else if (modifyMethod == "Add" && modifierType == "Int") {
        newValue = originalValue + (modifierValue * multiplier);
    } else if (modifyMethod == "Add" && modifierType == "Float") {
        newValue = originalValue + ((modifierValue / 100) * multiplier);
    } else if (modifierType == "Float") {
        newValue = ((modifierValue / 100) * multiplier);
    } else if (modifierType == "Int") {
        newValue = modifierValue * multiplier;
    } else {
        return modifierValue;
    }
    return Util.RoundToTwo(newValue);
});

Util.RemoveChildren = (function (panel) {
    for (var child in panel.Children()) {
        panel.Children()[child].DeleteAsync(0.0);
        panel.Children()[child].RemoveAndDeleteChildren();
    }
});

(function(){
	GameUI.CustomUIConfig().Util = Util;
})()