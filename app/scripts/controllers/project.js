'use strict';

angular.module('hopsWorksApp')
  .controller('ProjectCtrl', ['$scope', '$modalStack', '$location', '$routeParams'
    , 'growl', 'ProjectService', 'ModalService', 'ActivityService',
    function ($scope, $modalStack, $location, $routeParams, growl, ProjectService, ModalService, ActivityService) {

      var self = this;
      self.currentProject = [];
      self.activities = [];

      self.card = {};
      self.cards = [];
      self.projectMembers = [];

      // We could instead implement a service to get all the available types but this will do it for now
      self.projectTypes = ['CUNEIFORM','SAMPLES','STUDY_INFO', 'SPARK', 'ADAM', 'MAPREDUCE', 'YARN', 'ZEPPELIN'];
      self.alreadyChoosenServices = [];
      self.selectionProjectTypes = [];
      self.pId = $routeParams.projectID;

      ProjectService.get({}, {'id': self.pId}).$promise.then(
        function (success) {
          self.currentProject = success;
          self.projectMembers = self.currentProject.projectTeam;
          self.currentProject.services.forEach(function (entry) {
            self.alreadyChoosenServices.push(entry);
          });

          // Remove already choosen services from the service selection
          self.alreadyChoosenServices.forEach(function (entry) {
            var index = self.projectTypes.indexOf(entry.toUpperCase());
            self.projectTypes.splice(index, 1);
          });


        }, function (error) {
          $location.path('/');
        }
      );


      ActivityService.getByProjectId(self.pId).then(function (success) {
        self.activities = success.data;
        console.log(self.activities);
        self.pageSize = 10;
        self.totalPages = Math.floor(self.activities.length / self.pageSize);
        self.totalItems = self.activities.length;
      }, function (error) {

      });

      self.currentPage = 1;


      // Check if the service exists and otherwise add it or remove it depending on the previous choice
      self.exists = function (projectType) {
        var idx = self.selectionProjectTypes.indexOf(projectType);
        if (idx > -1) {
          self.selectionProjectTypes.splice(idx, 1);
        } else {
          self.selectionProjectTypes.push(projectType);
        }
      };


      self.projectSettingModal = function () {
        ModalService.projectSettings('lg').then(
          function (success) {
            growl.success("Successfully saved project: " + success.name, {title: 'Success', ttl: 5000});
          }, function () {
            growl.success("Successfully saved project.", {title: 'Success', ttl: 5000});
          });
      };


      self.saveProject = function () {

        $scope.newProject = {
          'projectName': self.projectName,
          'description': self.projectDesc,
          'services': self.selectionProjectTypes
        };

        ProjectService.update({id: self.currentProject.projectId}, $scope.newProject).$promise.then(
          function (success) {
            console.log(success);
            $modalStack.dismissAll();
          }, function (error) {
            console.log('Error: ' + error)
          }
        );

      };


      self.close = function () {
        $modalStack.dismissAll();
      };


      $scope.showHamburger = $location.path().indexOf("project") > -1;

      self.goToDatasets = function () {
        $location.path($location.path() + '/datasets');
      };

      self.goToSpecificDataset = function (id) {
        $location.path($location.path() + '/' + id);
      };


    }]);


/*******************************/
/* TESTING ALL CRUD OPERATIONS */
/*******************************/

// GET /api/project/
// $scope.projects = ProjectService.query();
// console.log($scope.projects);

// GET /api/project/1
// $scope.specificProject = ProjectService.get({}, {'id': 1});

// PUT /api/project/1
// $scope.specificProject.description = 'TESTING TO CHANGE VALUE';
// ProjectService.update({ id:$scope.specificProject.id }, $scope.specificProject );

// POST /api/project/
/*
 $scope.newProject = {
 'description':'Created a new project',
 'name':'TestProject',
 'status':0,
 'type':'Spark'
 }
 */

// POST /api/project/
// ProjectService.save($scope.newProject);

// DELETE /api/project/ THELATEST id
// ProjectService.delete({}, {'id': 35 });





