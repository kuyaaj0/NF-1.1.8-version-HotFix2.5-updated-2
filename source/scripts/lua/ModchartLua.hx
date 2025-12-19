package scripts.lua;

#if LUA_ALLOWED
import modchart.Manager;
import modchart.ManagerLua;
import flixel.tweens.FlxEase;
import flixel.FlxG;
import Reflect;

/**
 * Base Modchart Lua function bindings
 * by kuya aj & GPT-5 team ✨
 */
class ModchartLua {
    public static function implement(lua:Dynamic):Void {
        if (lua == null) {
            FlxG.log.warn("[ModchartLua] Skipped — Lua instance is null!");
            return;
        }

        // Ensure Manager exists
        if (Manager.instance == null) Manager.instance = new Manager();

        var addBinding = function(name:String, fn:Dynamic):Void {
            if (Reflect.hasField(lua, "addLocalCallback")) {
                Reflect.callMethod(lua, Reflect.field(lua, "addLocalCallback"), [name, fn]);
            } else if (Reflect.hasField(lua, "set")) {
                Reflect.callMethod(lua, Reflect.field(lua, "set"), [name, fn]);
            } else {
                FlxG.log.warn("[ModchartLua] Could not register binding: " + name);
            }
        };

        //------------------------------------------------------------
        // BASIC MODIFIER FUNCTIONS
        //------------------------------------------------------------
        addBinding('addMod', function(name:String, ?field:Int = -1) {
            Manager.instance.addModifier(name, field);
        });

        addBinding('setMod', function(name:String, value:Float, ?player:Int = -1, ?field:Int = -1) {
            Manager.instance.setPercent(name, value, player, field);
        });

        addBinding('getMod', function(name:String, ?player:Int = 0, ?field:Int = 0):Float {
            return Manager.instance.getPercent(name, player, field);
        });

        addBinding('resetMod', function(name:String) {
            Manager.instance.setPercent(name, 0);
        });

        //------------------------------------------------------------
        // BEAT + EASING CONTROLS
        //------------------------------------------------------------
        addBinding('easeMod', function(name:String, beat:Float, length:Float, value:Float, ease:String = "linear", ?player:Int = -1, ?field:Int = -1) {
            var easeFunc = Reflect.field(FlxEase, ease);
            if (easeFunc == null) easeFunc = FlxEase.linear;
            Manager.instance.ease(name, beat, length, value, easeFunc, player, field);
        });

        addBinding('addEaseMod', function(name:String, beat:Float, length:Float, value:Float, ease:String = "linear", ?player:Int = -1, ?field:Int = -1) {
            var easeFunc = Reflect.field(FlxEase, ease);
            if (easeFunc == null) easeFunc = FlxEase.linear;
            Manager.instance.add(name, beat, length, value, easeFunc, player, field);
        });

        //------------------------------------------------------------
        // CALLBACKS + REPEATERS
        //------------------------------------------------------------
        addBinding('callbackMod', function(beat:Float, funcName:String, ?field:Int = -1) {
            Manager.instance.callback(beat, function(e) {
                if (Reflect.hasField(lua, "call")) Reflect.callMethod(lua, Reflect.field(lua, "call"), [funcName, []]);
            }, field);
        });

        addBinding('repeaterMod', function(beat:Float, length:Float, funcName:String, ?field:Int = -1) {
            Manager.instance.repeater(beat, length, function(e) {
                if (Reflect.hasField(lua, "call")) Reflect.callMethod(lua, Reflect.field(lua, "call"), [funcName, []]);
            }, field);
        });

        //------------------------------------------------------------
        // PLAYFIELD CONTROL
        //------------------------------------------------------------
        addBinding('addPlayfield', function() {
            Manager.instance.addPlayfield();
        });

        //------------------------------------------------------------
        // ADDITIONAL LUA BRIDGE
        //------------------------------------------------------------
        ManagerLua.register(lua);

        FlxG.log.add("[ModchartLua] ✅ Modchart functions registered successfully!");
    }
}
#end
