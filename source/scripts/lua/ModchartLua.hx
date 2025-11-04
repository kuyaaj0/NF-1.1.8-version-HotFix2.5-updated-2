package scripts.lua;

#if LUA_ALLOWED
import modchart.Manager;
import flixel.tweens.FlxEase;
import flixel.FlxG;
import Reflect;

class ModchartLua {
    /**
     * Register modchart functions into the Lua runtime.
     * Accepts a Dynamic `lua` so it works with different Lua wrappers:
     * - older llua.State with addLocalCallback (if present)
     * - FunkinLua style with set(...) (if present)
     */
    public static function implement(lua:Dynamic):Void {
        if (lua == null) {
            FlxG.log.warn("[ModchartLua] Skipped — Lua instance is null!");
            return;
        }

        // Ensure Manager singleton exists
        if (Manager.instance == null) Manager.instance = new Manager();

        try {
            // Helper to add a binding compatible with both APIs
            var addBinding = function(name:String, fn:Dynamic):Void {
                // If lua has addLocalCallback (older API), use it
                if (Reflect.hasField(lua, "addLocalCallback")) {
                    Reflect.callMethod(lua, Reflect.field(lua, "addLocalCallback"), [name, fn]);
                    return;
                }

                // If lua has set(name, func) (FunkinLua / custom API), use it
                if (Reflect.hasField(lua, "set")) {
                    Reflect.callMethod(lua, Reflect.field(lua, "set"), [name, fn]);
                    return;
                }

                // Fallback: attempt to set a global (if supported)
                if (Reflect.hasField(lua, "globals") && Reflect.getProperty(lua, "globals") != null) {
                    var g = Reflect.getProperty(lua, "globals");
                    Reflect.setField(g, name, fn);
                    return;
                }

                // Last resort: warn (can't register)
                FlxG.log.warn("[ModchartLua] Could not register Lua binding: " + name);
            };

            // --- BASIC MODIFIERS ---
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

            // --- EVENTS / EASING ---
            addBinding('setModAtBeat', function(name:String, beat:Float, value:Float, ?player:Int = -1, ?field:Int = -1) {
                Manager.instance.set(name, beat, value, player, field);
            });

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

            // --- CALLBACKS / REPEATERS ---
            // These require calling a Lua function by name later. Different runtimes expose different call methods.
            // We detect a "call" method first; otherwise we try "pcall" or fallback to logging a warning.
            var callLuaFunction = function(funcName:String, ?args:Array<Dynamic>) {
                if (args == null) args = [];
                Lua.call(lua, funcName, args);
            
                try {
                    if (Reflect.hasField(lua, "call")) {
                        Reflect.callMethod(lua, Reflect.field(lua, "call"), [funcName, args]);
                    } else if (Reflect.hasField(lua, "pcall")) {
                        // some wrappers expose pcall(luaState, funcName, args) semantics - try
                        Reflect.callMethod(lua, Reflect.field(lua, "pcall"), [funcName, args]);
                    } else if (Reflect.hasField(lua, "rawcall")) {
                        Reflect.callMethod(lua, Reflect.field(lua, "rawcall"), [funcName, args]);
                    } else {
                        // no reliable call method — attempt a common 'callByName' or warn
                        if (Reflect.hasField(lua, "functions") && Reflect.getProperty(lua, "functions") != null) {
                            var fcontainer = Reflect.getProperty(lua, "functions");
                            if (Reflect.hasField(fcontainer, "exists") && Reflect.callMethod(fcontainer, Reflect.field(fcontainer, "exists"), [funcName]) == true) {
                                // Try calling via functions container if it has a call method
                                try {
                                    Reflect.callMethod(fcontainer, Reflect.field(fcontainer, "call"), [funcName, args]);
                                } catch(e) {
                                    FlxG.log.warn("[ModchartLua] Could not call function via functions container: " + e);
                                }
                            }
                        } else {
                            FlxG.log.warn("[ModchartLua] No callable API found to call Lua function: " + funcName);
                        }
                    }
                } catch (err) {
                    FlxG.log.warn("[ModchartLua] Error calling Lua function '" + funcName + "': " + err);
                }
            };

            addBinding('callbackMod', function(beat:Float, funcName:String, ?field:Int = -1) {
                Manager.instance.callback(beat, function(e) {
                    callLuaFunction(funcName, []);
                }, field);
            });

            addBinding('repeaterMod', function(beat:Float, length:Float, funcName:String, ?field:Int = -1) {
                Manager.instance.repeater(beat, length, function(e) {
                    callLuaFunction(funcName, []);
                }, field);
            });

            // --- PLAYFIELD UTILITY ---
            addBinding('addPlayfield', function() {
                Manager.instance.addPlayfield();
            });

            FlxG.log.add("[ModchartLua] ✅ Fully registered Modchart functions successfully!");
        } catch (e:Dynamic) {
            FlxG.log.error("[ModchartLua] ❌ Error while registering Modchart functions: " + e);
        }
    }
}
#end
