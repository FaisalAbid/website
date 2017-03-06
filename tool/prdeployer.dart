// Copyright (c) 2017, FaisalAbid. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

import 'package:firebase/firebase_io.dart';
import 'dart:async';
import 'package:github/server.dart';
import 'dart:io';

GitHub github;
String firebaseAuth;
PullRequest currentPullrequest;

String firebaseRoot = "https://flutter-web-controller.firebaseio.com/flutter/pulls";

main(List<String> arguments) async {
  String branchName = arguments[0];
  Map env = Platform.environment;
  github = createGitHubClient(auth: new Authentication.withToken(env["GITHUB_TOKEN"]));
  firebaseAuth = arguments[1];

  FirebaseClient fbClient = new FirebaseClient(firebaseAuth);

  List prsList = await getPullRequests();
  for (PullRequest p in prsList) {
    if (branchName == p.head.ref) {
      currentPullrequest = p;
      break;
    }
  }

  String rootPath = "${firebaseRoot}.json";

  Map projectsData = await fbClient.get(rootPath);
  String projectToDeploy;

  await projectsData.forEach((String key, Map value) async {
    if (value["branch"] == branchName) {
      // this has already been deployed.
      // deploy again
      projectToDeploy = value["name"];
    } else {
      bool oldBranch = await isBranchOld(value["branch"]);
      if (oldBranch) {
        await fbClient.patch("${firebaseRoot}/$key.json", {"branch": null});
      }
    }
  });

  if (projectToDeploy == null) {
    await projectsData.forEach((String key, Map value) async {
      if (projectToDeploy != null) {
        // project already set
        // todo: remove this foreach with a better iterator pattern
        return;
      }
      projectToDeploy = value["name"];
      await fbClient.patch("${firebaseRoot}/$key.json", {"branch": branchName});
      await postLinkToGithub(projectToDeploy, currentPullrequest);
    });
  }

  print(projectToDeploy);
}

Future<bool> isBranchOld(String branchName) async {
  List prsList = await getPullRequests();
  for (PullRequest p in prsList) {
    if (branchName == p.head.ref) {
      return false;
    }
  }
  return true;
}

Future<List> getPullRequests() async {
  Stream<PullRequest> prs = await github.pullRequests.list(new RepositorySlug.full("flutter/website"));
  List prsList = await prs.toList();
  return prsList;
}

Future<IssueComment> postLinkToGithub(String projectToDeploy, PullRequest request) async {
  if (request == null) {
    return null;
  }
  IssueComment issueComment = await github.issues.createComment(
      new RepositorySlug.full("flutter/website"),
      request.number,
      "Staging URL Generated At ${projectToDeploy}. Please allow Travis Build to finish to view the URL.");
  return issueComment;
}
