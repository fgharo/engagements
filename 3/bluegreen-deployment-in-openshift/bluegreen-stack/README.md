# About Application
Stacked blue green rectangles. The top rectangle has the title and version of the app.



# Simulate Blue Green Deployment on Openshift

I have already preseeded a few app container image versions on quay.io from tag 1.0 til 5.0. 
For example, the fully qualified docker image name for tag 1.0 is quay.io/user15/bluegreen-stack:1.0.

Prereqs:
1. Whatever openshift namespace you do your deployments make sure it exists first and update PROJECT environment variable in .openshift/scripts/env.properties

For my case, I assumed a project namespace of bluegreen-prod
```
oc new-project bluegreen-prod
```

2. Lets change to the directory that will have our scripts so we can simulate the functions of a blue green deployment.
```
cd bluegreen-stack/.openshift/scripts
```

Note: The scenarios below build on each other. So read top down or in order Scenario 1, Scenario 2, ...

Also, when the scripts switch over traffic from blue to green (or vice versa), there might be some lag, so if you see the same ui come up, try hitting the refresh button on your browser.


## Scenario 1 - First Deployment/Rollout Preview ever.

Since this is the very first deployment, thus route never existed before, thus there is no traffic from customers as
there would of been no route for them to go. Therefore, we will have both a preview and active route point to the same
live deployment to start.

Also, I adopt convention that we start with color blue. Notice blue and green allow us to implement our switch over logic
throughout the different scripts under .openshift/scripts/

Anyhow, lets rollout our first preview or do our first deployment ever!

```
./rollout-preview.sh quay.io/user15/bluegreen-stack:1.0
```

Two routes should of been created. You can get them from the Openshift web console or via oc cli:
```
oc get route bluegreen-stack # The active route
oc get route bluegreen-stack-preview
```

Navigating to either in a browser, you should notice a stack with one block on it and the title:
Blue Green Stack

Notice both point to service bluegreen-stack-blue


## Scenario 2 - Second Deployment (Rollout Preview & Rollout Promotion).

Developers made changes, and it got all the way to Production!

Rollout the preview of our second update to the bluegreen-stack application.
```
./rollout-preview.sh quay.io/user15/bluegreen-stack:2.0
```

Two things to notice after this script completes:
1. There are now two kubernetes Deployment objects out in namespace bluegreen-prod with 1 pod each.
2. The preview route has been updated to point to this green deployment. The active route
still points to the old blue deployment or version 1.0 of our app.

When you look at the respective uis in the browser you will see a difference too. The preview route
will take you to version 2.0 of the app. A green block is stacked on top of the old blue block with
title:
Blue Green Stack 2.0

After significant testing, we have decided that we are ready to go online with version 2.0 or the
preview/green deployment. This time, we have to run a second script:

```
./promote-preview.sh
```

This will point the active route to the new app we just previewed and scale down the old blue version to 0 pods.


## Scenario 3 - Third Deployment (Rollout Preview & Rollout Promotion).

Lets make this scenario go quickly just to get the point of switching back between the existing blue and green deployments
created from the last two scenarios, as well as seeing how the active and preview routes are affected.

```
./rollout-preview.sh quay.io/user15/bluegreen-stack:3.0
# Inspect the preview route and see that there are now 3 blocks in the ui, with blue on top
# Were ready to promote
./promote-preview.sh
```

## Scenario 4 - Rollback the active application

Business wants us to rollback to version 2.0. 

```
./rollback-active.sh
```

After executing this, you should notice that we scale the green deployment up to the same number of pods
as the current active blue deployment. Then the active and preview routes will
point back to the version 2.0 of the app even though the endpoints stay the same. Testers should be happy.

Finally, the blue deployment or version 3.0 should begin to scale down to 0 pods as we don't need that running anymore.



## Clean up the project

If you need to restart and need resources cleared up:
```
oc delete all --all -n bluegreen-prod
```



# BluegreenStack Local Development

This project was generated with [Angular CLI](https://github.com/angular/angular-cli) version 12.2.1.

## Development server

Run `ng serve` for a dev server. Navigate to `http://localhost:4200/`. The app will automatically reload if you change any of the source files.

## Code scaffolding

Run `ng generate component component-name` to generate a new component. You can also use `ng generate directive|pipe|service|class|guard|interface|enum|module`.

## Build

Run `ng build` to build the project. The build artifacts will be stored in the `dist/` directory.

## Running unit tests

Run `ng test` to execute the unit tests via [Karma](https://karma-runner.github.io).

## Running end-to-end tests

Run `ng e2e` to execute the end-to-end tests via a platform of your choice. To use this command, you need to first add a package that implements end-to-end testing capabilities.

## Further help

To get more help on the Angular CLI use `ng help` or go check out the [Angular CLI Overview and Command Reference](https://angular.io/cli) page.


# BluegreenStack Build App Container Image

Still to come ...



