angular.module('timing', [])
.directive('focusInput', function($timeout) {
  return {
    link: function(scope, element, attrs) {
      element.bind('click', function() {
        $timeout(function() {
          element.parent().find('input')[0].focus();
        });
      });
    }
  };
})
.controller('MainCtrl', [
  '$scope','$http','$window',
  function($scope,$http,$window){
    $scope.name1 = '';
    $scope.location1 = '';
    $scope.number1 = '';
    $scope.threshold1 = '';
    $scope.eci = $window.location.search.substring(1);

    var bURL = 'http://localhost:3000' + '/sky/event/'+$scope.eci+'/eid/wovyn/updated_values';
    $scope.updateVals = function() {
      var pURL = bURL + "?location=" + $scope.location + "&name=" + $scope.name + "&threshold=" + $scope.threshold + "&sms=" + $scope.number;
      return $http.post(pURL).success(function(data){
        $scope.getAll();
        $scope.location='';
        $scope.name='';
        $scope.threshold='';
        $scope.number='';
      });
    };

    var threshURL = 'http://localhost:3000' + '/sky/cloud/'+$scope.eci+'/wovyn_base/getThreshold';
    var locURL = 'http://localhost:3000' + '/sky/cloud/'+$scope.eci+'/wovyn_base/getLocation';
    var nameURL = 'http://localhost:3000' + '/sky/cloud/'+$scope.eci+'/wovyn_base/getName';
    var toURL = 'http://localhost:3000' + '/sky/cloud/'+$scope.eci+'/wovyn_base/getTo';
    $scope.getAll = function() {
      $http.get(threshURL).success(function(data){
        console.log(data);
        $scope.threshold1 = data;
      });
      $http.get(locURL).success(function(data){
        $scope.location1 = data;
      });
      $http.get(nameURL).success(function(data){
        $scope.name1 = data;
      });
      return $http.get(toURL).success(function(data){
        $scope.number1 = data;
      });
    };

    $scope.getAll();


  }
]);
