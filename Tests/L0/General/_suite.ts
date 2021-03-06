/// <reference path="../../../definitions/mocha.d.ts"/>
/// <reference path="../../../definitions/node.d.ts"/>
/// <reference path="../../../definitions/Q.d.ts"/>

import Q = require('q');
import assert = require('assert');
import path = require('path');
import fs = require('fs');

describe('General Suite', function() {

	before((done) => {
		// init here
		done();
	});

	after(function() {
		
	});

	it('Find invalid task.json', (done) => {
		this.timeout(1000);
		
		var tasksRootFolder =  path.resolve(__dirname, '../../../../Tasks');
		
		var taskFolders: string[] = [];
		fs.readdirSync(tasksRootFolder).forEach(folderName=> {
			if(fs.statSync(path.join(tasksRootFolder, folderName)).isDirectory()) { 
				taskFolders.push(path.join(tasksRootFolder, folderName));	
			}
		})

		for(var i = 0; i < taskFolders.length; i++) {
			var taskFolder = taskFolders[i];

			var taskjson = path.join(taskFolder, 'task.json');
			var jsonString = fs.readFileSync(taskjson).toString();
			if(jsonString.indexOf('\uFEFF') >= 0) {
				console.warn('the JSON has a \'Zero Width No-Break Space\', this may cause JSON parse failed.');
				console.warn('try to remove all zero-width characters, this may generated pending changes, you need to check them in.');
				var fixedJsonString = jsonString.replace(/[\uFEFF]/g, '');
				fs.writeFileSync(taskjson, fixedJsonString);
				assert(false, 'need check-in \'U+FEFF\' fix for: ' + taskjson);
			}
			try
			{
				var task = JSON.parse(fs.readFileSync(taskjson).toString());
			}
			catch(err)
			{
				assert(false, err.message + '\n\tunable to parse JSON from: ' + taskjson);				
			}
		}
		
		done();
	})
	
    it('Find .js with uppercase', (done) => {
		this.timeout(1000);
		
		var tasksRootFolder =  path.resolve(__dirname, '../../../../Tasks');
		
		var taskFolders: string[] = [];
		fs.readdirSync(tasksRootFolder).forEach(folderName=> {
			if(fs.statSync(path.join(tasksRootFolder, folderName)).isDirectory()) { 
				taskFolders.push(path.join(tasksRootFolder, folderName));	
			}
		})

		for(var i = 0; i < taskFolders.length; i++) {
			var taskFolder = taskFolders[i];

			var taskjson = path.join(taskFolder, 'task.json');
            var task = require(taskjson);
            
            if (task.execution['Node']) {
				
				var tsFiles = fs.readdirSync(taskFolder).filter(file => {
					return file.search(/\.ts$/) > 0;
				})
				
				tsFiles.forEach(tsFile => {
                    if(tsFile.search(/[A-Z]/g) >= 0) {
                        console.error('Has uppercase in .ts file name for tasks: ' + path.relative(tasksRootFolder, taskjson));
                        assert(false, 'Has uppercase is dangerous for xplat tasks.' + taskjson);
                    }
				})
				
                var targetJs = task.execution['Node'].target;
                if(targetJs.search(/[A-Z]/g) >= 0) {
                    console.error('Has uppercase in task.json\'s excution.node.target for tasks: ' + path.relative(tasksRootFolder, taskjson));
                    assert(false, 'Has uppercase is dangerous for xplat tasks.' + taskjson);
                }
			}
		}
		
		done();
	})
    
    it('Find unsupported demands', (done) => {
		this.timeout(1000);
		
        var supportedDemands :string[] = ['AndroidSDK', 'ant', 'AzurePS', 'Chef', 
                                          'DotNetFramework', 'java', 'JDK', 'maven',
                                          'MSBuild', 'MSBuild_x64', 'npm', 'node.js',
                                          'PowerShell', 'SqlPackage', 'VisualStudio', 'VisualStudio_IDE',
                                          'VSTest', 'WindowsKit', 'WindowsSdk', 'cmake',
                                          'cocoapods', 'curl', 'Cmd', 'sh',
                                          'KnifeReporting', 'Xamarin.Android', 'Xamarin.iOS', 'xcode'];
        
        supportedDemands.forEach(demand => {
            if(supportedDemands.indexOf(demand.toLocaleLowerCase()) < 0) {
                supportedDemands.push(demand.toLocaleLowerCase());    
            }
        });
        
		var tasksRootFolder =  path.resolve(__dirname, '../../../../Tasks');
		
		var taskFolders: string[] = [];
		fs.readdirSync(tasksRootFolder).forEach(folderName=> {
			if(fs.statSync(path.join(tasksRootFolder, folderName)).isDirectory()) { 
				taskFolders.push(path.join(tasksRootFolder, folderName));	
			}
		})

        var unsupportedDemands :string[] = [];        
		for(var i = 0; i < taskFolders.length; i++) {
			var taskFolder = taskFolders[i];
			var taskjson = path.join(taskFolder, 'task.json');            
            
            var task = require(taskjson);
            if (task.hasOwnProperty('demands')) {
                task['demands'].forEach(demand => {
                    if(supportedDemands.indexOf(demand.toLocaleLowerCase()) < 0) {
                        console.warn('find unsupported demand: ' + demand + ' in ' + taskjson);
                        console.warn('fix the unit test if the new demand is added on purpose.');
                        unsupportedDemands.push(demand);
                    }
                });
			}
		}
		
        if(unsupportedDemands.length > 0) {
            assert(false, 'find unsupported demands, please take necessary operation to fix this. unsupported demands count: ' + unsupportedDemands.length);
        }
        
		done();
	})
});
