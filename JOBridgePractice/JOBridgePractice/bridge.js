if (typeof global == "undefined") {
    global = this;
}
//用于存储所有的实现了JOBExport协议的模型
var __JOBModels = {};

(function() {
    var tag = 1,
        modules = __JOBModels, //用于存放所有模型
        modulesConfig = {}, //用于存放模型的属性
        callbacks = {}, //存储回调模型
        instances = {}, //存储实例列表
        cbId = 1,
        toString = {}.toString(); //toString函数
    //方法
    function baseModule() {}
    //0 jsonvalue  1 function id  2 Class
    //把对应实例的模型转换为对应的js对象返回
    function moduleData(instance) {
        var json = {
            moduleName: instance.moduleName,
            tag: instance.tag
        };
        //获取模型的属性列表
        var properties = modulesConfig[instance.moduleName].properties;
        if (properties) {
            for (var property in properties) {
                json[property] = instance[property];
            }
        }
        return json;
    }
    //类型转换
    function convertValue(v) {
        var type = 0;
        if (v instanceof Function) {
            type = 1;
            callbacks[cbId] = v;
            v = cbId++;
        } else if (v instanceof baseModule) {
            type = 2;
            if (!v.tag) {
                //First load.
                v.tag = tag++;
                instances[v.tag] = v;
            } else if (!instances[v.tag]) {
                //TODO: check instance throw error.
            }
            v = moduleData(v);
        } else {
            //TODO: Check json value
        }
        return [type, v];
    }
    //把参数转换为js类型的参数
    function convertArguments(args) {
        var converted = [];
        for (var i = 0, l = args.length; i < l; i++) {
            converted.push(convertValue(args[i]));
        }
        return converted;
    }
    //把OC的类方法与对应JS对象的类方法设置好
    function setClassMethod(module, method, setting) {
        module[method] = function() {
            __JOBContextSend("callClassMethod", [module.moduleName, method, convertArguments(arguments)]);
        }
    }
    //把OC的实例方法与对应JS对象的实例方法设置好
    function setInstanceMethod(proto, method, setting) {
        proto[method] = function() {
            //TODO: Need check been loaded
            __JOBContextSend("callInstanceMethod", [this.tag, method, convertArguments(arguments)]);
        }
    }

    //实现继承的函数
    function mixin(obj, source) {
        if (obj && source) {
            for (var key in source) {
                if (Object.getOwnPropertyDescriptor) {
                    Object.defineProperty(obj, key, Object.getOwnPropertyDescriptor(source, key));
                } else {
                    obj[key] = source[key];
                }
            }
        }
        return obj;
    }
    //实现继承
    function inherits(parent, methods) {
        function module(methods) {
            if (this instanceof baseModule) {
                //new instance
                if (this.init instanceof Function) {
                    this.init.apply(this, arguments);
                }
            } else {
                //inherits modules		
                return inherits(arguments.callee, methods);
            }
        }
        var proto = module.prototype = new parent();
        proto.constructor = module;
        mixin(proto, methods);
        mixin(module, parent);
        return module;
    }
    //注册一个OC模型对应的JS模型
    function registerModule(config) {
        var name = config.moduleName;
        var module = inherits(baseModule, {});
        //把模型添加到modules、和modulesConfig
        modules[name] = module;
        modulesConfig[name] = config;

        module.moduleName = name;
        module.prototype.moduleName = name;
        //设置oc对应js类方法
        for (var name in config.classMethods) {
            setClassMethod(module, name, config.classMethods[name]);
        }
        //设置oc对应的js实例方法
        for (var name in config.instanceMethods) {
            setInstanceMethod(module.prototype, name, config.instanceMethods[name]);
        }
    }

    var commands = {
        registerModules: function(config) {
            for (var name in config) {
                registerModule(config[name]);
            }
        },
        triggerEvent: function(tag, name, data) {
            name = "on" + name.slice(0, 1).toUpperCase() + name.slice(1);
            var instance = instances[tag];
            if (instance) {
                //Check Function
                instance[name] && instance[name].call(instance, data);
            } else {
                //TODO: check instance not found.
            }
        },
        callback: function(id, args) {
            var fn = callbacks[id];
            if (!fn) {
                //TODO: throw repeat callback error.
            } else {
                delete callbacks[id];
                fn.apply(null, args);
            }
        },
        mapInstance: function(tag, name, options) {
            var module = new global[name](options);
            module.tag = tag;
            instances[module.tag] = module;
            commands.triggerEvent(tag, "load");
        },
    };
    global["__JOBConextReceiver"] = function(method, args) {
        commands[method].apply(null, args);
    }

})();
