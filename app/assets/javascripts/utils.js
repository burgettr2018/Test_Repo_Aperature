/** Utility Functions */

(function() {
	/**
	 * @requires HBS
	 */
	var module = {};

	module.isMobile = function() {
		var retVal = false;
		if ('matchMedia' in window) {
			retVal = window.matchMedia('(max-width: 767px)').matches;
		} else {
			retVal = $(window).width() < 768
		}

		return retVal;
	};

    module.findObjInArray = function (array, object) {
        for (var i = 0; i < array.length; i++) {
            if (JSON.stringify(array[i]) === JSON.stringify(object)) {
                return i;
            }
        }
        return -1;
    };

	module.isAndroidBrowser = function(){
		var nua = navigator.userAgent;
		var isAndroid = (nua.indexOf('Mozilla/5.0') > -1 && nua.indexOf('Android') > -1 && nua.indexOf('AppleWebKit') > -1 && nua.indexOf('Chrome') === -1);
		if (isAndroid) {
			return isAndroid;
		}
	};

    module.hashObject = function() {
        var _list = []; //storing as list to keep history and order of click events.

        window.location.hash.substring(1).replace(/([^&=]+)=?([^&]*)(?:&+|$)/g, function(match, key, value) {
            //(map[key] = map[key] || []).push(value);
            //_list.push({"key":key,"value":value})
            if (key != "~") {
                setParam(key, value);
            }

        });

        function map(){
            var m = [];
            for(var i=0;i<_list.length;i++){
                if(!m[_list[i].key]){
                    m[_list[i].key] = [];
                }
                m[_list[i].key].push(_list[i].value);
            }
            return m;
        }

        function toString(){
            var query = "";
            for(var i=0;i<_list.length;i++){
                query +=_list[i].key+"="+_list[i].value;
                if(i!= _list.length-1){
                    query+="&";
                }
            }
            return query;
        }

        function removeParam(key,value){
            for(var i=0;i<_list.length;i++){
                if(_list[i].key == key.toString() && (typeof value == 'undefined' || _list[i].value == value.toString())){
                    _list.splice(i, 1);
                }
            }
        }

        function setParam(key,value,clearOthersWithKey){
            if(clearOthersWithKey){
                removeParam(key)
            }
            _list.push({"key":key.toString(),"value":value.toString()})
        }

        return  {
            toString:toString,
            params:function(){
                return map();
            },
            get:function(param){
                return map()[param]||[];
            },
            first:function(param){
                var v = map()[param];
                return v && v.length > 0 ? v[0] : null;
            },
            setParamOnHash:function(name,value){
                setParam(name,value,true);
                //map[name] = [];
                //map[name].push(value.toString());
            },
            addParamOnHash:function(name,value){
                setParam(name,value);
                //if(!map[name]) {
                //    map[name] = [];
                //}
                //map[name].push(value.toString());
            },
            removeParamOnHash:function(key,value){
                removeParam(key,value)
                //if(map[name]){
                //    var index = map[name].indexOf(value.toString())
                //    while(index > -1) {
                //        map[name].splice(index, 1);
                //        index = map[name].indexOf(value.toString())
                //    }
                //}
            },
            apply:function(){
                var hash = toString();
                if(hash.length > 0){
                    window.location.hash = "#"+hash;
                }
                else {
                    //don't ever set an empty hash or the page will jump to the top
                    //hack to just set first tab if we don't have any filters
                    window.location.hash = "#~";
                }
            }
        };
    }

	/* Switch Functions End */

	HBS.namespace('OC.utils', module);
}());
