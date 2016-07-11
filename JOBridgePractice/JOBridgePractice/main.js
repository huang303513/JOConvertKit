var Test = __JOBModules.Test({
                             onLoad: function(){
                             this.getAttr("ttttt", function(data){
                                          Test.log(data);
                                          })
                             }
                             })


var MyApp = __JOBModules.App({
                             onLoad: function(){
                             var self = this;
                             Test.asyncData("abc", "dd", function(a,b,c){
                                            Test.log([a, b, c]);
                                            });
                             var myTest = new Test();
                             self.load(myTest);
                             }
                             });