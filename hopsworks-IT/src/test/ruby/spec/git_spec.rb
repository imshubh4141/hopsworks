=begin
 This file is part of Hopsworks
 Copyright (C) 2021, Logical Clocks AB. All rights reserved

 Hopsworks is free software: you can redistribute it and/or modify it under the terms of
 the GNU Affero General Public License as published by the Free Software Foundation,
 either version 3 of the License, or (at your option) any later version.

 Hopsworks is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
 without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
 PURPOSE.  See the GNU Affero General Public License for more details.

 You should have received a copy of the GNU Affero General Public License along with this program.
 If not, see <https://www.gnu.org/licenses/>.
=end

describe "On #{ENV['OS']}" do
  after(:all) {clean_all_test_projects(spec: "git")}
  before :all do
    @debugOpt=false
    with_valid_project
  end
  describe "Perform git operations" do
    describe "Provider configuration" do
      it 'should indicate all providers as not configured' do
        get_providers()
        expect_status_details(200)
        expect(json_body[:count]).to eq(0)
      end

      ['GitHub', 'GitLab', 'BitBucket'].each do |provider_to_configure|
        it "should indicate configured after configuration #{provider_to_configure}" do
          configure_git_provider(provider_to_configure)
          get_providers()
          expect_status_details(200)
          expect(json_body[:count]).to eq(1)
          expect(json_body[:items][0][:gitProvider]).to eql provider_to_configure
          expect(json_body[:items][0][:username]).to eql "username"
          expect(json_body[:items][0][:token]).to eql "token"
          delete_provider_configuration(provider_to_configure)
        end
      end

      it "should update a provider configuration" do
        configure_git_provider("GitHub", token="new token")
        get_providers()
        expect_status_details(200)
        expect(json_body[:count]).to eq(1)
        expect(json_body[:items][0][:gitProvider]).to eql "GitHub"
        expect(json_body[:items][0][:username]).to eql "username"
        expect(json_body[:items][0][:token]).to eql "new token"
        delete_provider_configuration("GitHub")
      end
    end
    describe "Cloning repositories" do
      before(:all) do
        @dir_name = "/Projects/#{@project[:projectname]}/Jupyter/testDir#{short_random_id}"
        create_dir(@project, @dir_name, query: "&type=DATASET")
        expect_status_details(201)
      end
      after(:all) do
        delete_dataset(@project, @dir_name)
      end
      git_providers = ['GitHub', 'GitLab']
      git_providers.each do |git_provider|
        it "should clone a #{git_provider} repository" do
          clone_dir = "#{@dir_name}/testDir#{short_random_id}"
          create_dir(@project, clone_dir, query: "&type=DATASET")
          expect_status_details(201)
          clone_config = get_clone_config(git_provider, @project[:projectname],  url="", branch="", path=clone_dir)
          repo_id, repo_path = clone_repo(@project[:id], clone_config)
          expect(repo_id).not_to be_nil
          expect(repo_path).not_to be_nil
          delete_repository(@project[:id], repo_path)
        end
        it "should clone a single branch - #{git_provider}" do
          branch = ""
          if git_provider == "GitHub"
            branch = "livy_dep"
          elsif git_provider == "GitLab"
            branch = "hopsworks"
          end
          clone_dir = "#{@dir_name}/testDir#{short_random_id}"
          create_dir(@project, clone_dir, query: "&type=DATASET")
          expect_status_details(201)
          clone_config = get_clone_config(git_provider, @project[:projectname], url="", branch=branch, path=clone_dir)
          repo_id, repo_path = clone_repo(@project[:id], clone_config)
          expect(repo_id).not_to be_nil
          expect(repo_path).not_to be_nil
          delete_repository(@project[:id],repo_id)
        end
      end
    end
    describe "Fail operations on unconfigured provider" do
      it "should fail to clone a BitBucket repository" do
        dir_name = "/Projects/#{@project[:projectname]}/Jupyter/testDir#{short_random_id}"
        create_dir(@project, dir_name, query: "&type=DATASET")
        expect_status_details(201)
        clone_config = get_clone_config("BitBucket", @project[:projectname], url="", branch="",  dir_name)
        do_clone_git_repo(@project[:id], clone_config)
        expect_status_details(400, error_code: 500029)
      end
      it 'should fail to pull a GitLab repository' do
        dir_name = "/Projects/#{@project[:projectname]}/Jupyter/testDir#{short_random_id}"
        create_dir(@project, dir_name, query: "&type=DATASET")
        expect_status_details(201)
        clone_config = get_clone_config("GitLab", @project[:projectname], url="", branch="", dir_name)
        repo_id, repo_path = clone_repo(@project[:id], clone_config)
        expect(repo_id).not_to be_nil
        expect(repo_path).not_to be_nil
        git_pull(@project[:id], repo_id)
        expect_status_details(400, error_code: 500029)
        delete_repository(@project[:id], repo_id)
      end
      git_providers = ['GitHub', 'GitLab']
      git_providers.each do |git_provider|
        it "should fail to push on a #{git_provider} repository" do
          dir_name = "/Projects/#{@project[:projectname]}/Jupyter/testDir#{short_random_id}"
          create_dir(@project, dir_name, query: "&type=DATASET")
          expect_status_details(201)
          clone_config = get_clone_config(git_provider, @project[:projectname], url="", branch="", dir_name)
          repo_id, repo_path = clone_repo(@project[:id], clone_config)
          expect(repo_id).not_to be_nil
          expect(repo_path).not_to be_nil
          git_push(@project[:id], repo_id)
          expect_status_details(400, error_code: 500029)
          delete_repository(@project[:id], repo_id)
        end
      end
    end
    describe "Getting project repositories" do
      before (:all) do
        @project1 = create_project
      end
      it 'should get all repositories in the project' do
        clone_config = get_clone_config("GitHub", @project1[:projectname])
        repo_id, _ = clone_repo(@project1[:id], clone_config)

        get_project_git_repositories(@project1[:id])
        expect(json_body[:count]).to eq(1)
        expect(json_body[:items][0][:creator][:email]).to be nil

        get_project_git_repositories(@project1[:id], query="?expand=creator")
        expect(json_body[:count]).to eq(1)
        expect(json_body[:items][0][:creator][:email]).not_to be_nil

        delete_repository(@project1[:id], repo_id)
      end
      describe '#sort' do
        before(:all) do
          repositories = clone_repositories(@project1[:id], @project1[:projectname], {"GitHub" => "https://github.com/logicalclocks/livy-chef.git", "GitLab" => "https://gitlab.com/gibchikafa/test_repo.git"})
          expect(repositories.keys.count).to be > 1
        end
        after(:all) do
          get_project_git_repositories(@project1[:id], query="?expand=creator")
          expect(json_body[:count]).to be > 1
          repositories = json_body[:items]
          repositories.each{|r| delete_repository(@project1[:id], r[:id])}
        end
        it 'should get all repositories sorted by id (asc)' do
          test_sort_by_id(@project1[:id])
        end
        it 'should get all repositories sorted by id (desc)' do
          test_sort_by_id(@project1[:id], "desc")
        end
        it 'should get all repositories sorted by name (asc)' do
          test_sort_by_repo_name(@project1[:id])
        end
        it 'should get all repositories sorted by name (desc)' do
          test_sort_by_repo_name(@project1[:id], "desc")
        end
      end
      describe "#user repositories" do
        it 'should filter repositories by user' do
          clone_config = get_clone_config("GitHub", @project1[:projectname])
          repoId1, path1 = clone_repo(@project1[:id], clone_config)
          member = create_user
          add_member_to_project(@project1, member[:email], "Data scientist")
          reset_session
          create_session(member[:email],"Pass123")
          clone_config = get_clone_config("GitLab", @project1[:projectname])
          repoId2, path2 = clone_repo(@project1[:id], clone_config)
          get_project_git_repositories(@project1[:id], "?expand=creator")
          expect(json_body[:count]).to eq(1)
          expect(json_body[:items][0][:creator][:username]).to eql member[:username]
          reset_session
          create_session(@project1[:username], "Pass123")
          get_project_git_repositories(@project1[:id], "?expand=creator")
          expect(json_body[:count]).to eq(1)
          expect(json_body[:items][0][:creator][:username]).to eql @user[:username]
          delete_repository(@project1[:id], repoId1)
          delete_repository(@project1[:id], repoId2)
        end
      end
    end
    describe "unauthorized user" do
      before (:all) do
        @project2 = create_project
      end
      after (:each) do
        reset_session
        create_session(@project[:username],"Pass123")
      end
      it 'it should fail to do a git operation if the user is not the owner of the repository' do
        clone_config = get_clone_config("GitHub", @project2[:projectname])
        repoId, path = clone_repo(@project2[:id], clone_config)
        member = create_user
        add_member_to_project(@project2, member[:email], "Data scientist")
        reset_session
        create_session(member[:email],"Pass123")
        # try performing a git operation
        do_create_branch(@project2[:id], repoId, "hopper")
        expect_status_details(403, error_code: 500035)
      end
    end
    describe "Perform operations on the cloned repositories" do
      after :each do
        get_project_git_repositories(@project[:id])
        if json_body[:count] > 0
          repositories = json_body[:items]
          repositories.each{|r| delete_repository(@project[:id], r[:id])}
        end
      end
      it 'should retrieve repository by its id' do
        clone_config = get_clone_config("GitHub", @project[:projectname], url="https://github.com/logicalclocks/livy-chef.git")
        repository_id, repository_path = clone_repo(@project[:id], clone_config)
        get_repository(@project[:id], repository_id)
        expect(repository_id).to be == json_body[:id]
        expect(repository_path).to be == json_body[:path]
      end
      it "should get executions performed in the repository" do
        clone_config = get_clone_config("GitHub", @project[:projectname], url="https://github.com/logicalclocks/livy-chef.git")
        repository_id, _ = clone_repo(@project[:id], clone_config)
        get_git_executions(@project[:id], repository_id)
        expect(json_body[:count]).to be > 0
        expect(json_body[:items][0][:repository][:path]).to be nil
        expect(json_body[:items][0][:user][:email]).to be nil
        # Check expansions
        get_git_executions(@project[:id], repository_id, query="?expand=repository&expand=user")
        expect(json_body[:count]).to be > 0
        expect(json_body[:items][0][:repository][:path]).not_to be_nil
        expect(json_body[:items][0][:user][:email]).not_to be_nil
      end
      it "should get repository default branches after cloning" do
        clone_config = get_clone_config("GitHub", @project[:projectname])
        repository_id, _ = clone_repo(@project[:id], clone_config)
        get_repository_branches(@project[:id], repository_id)
        expect_status_details(200)
        expect(json_body[:count]).to be > 0
      end
      it "should get the repository default branch commits" do
        clone_config = get_clone_config("GitHub", @project[:projectname])
        repository_id, _ = clone_repo(@project[:id], clone_config)
        get_repository(@project[:id], repository_id)
        expect_status_details(200)
        get_branch_commits(@project[:id], repository_id, json_body[:currentBranch])
        expect_status_details(200)
        expect(json_body[:count]).to be > 0
      end
      it "should create a branch" do
        clone_config = get_clone_config("GitHub", @project[:projectname])
        repository_id, _ = clone_repo(@project[:id], clone_config)
        test_branch = "test_branch"
        create_branch(@project[:id], repository_id, test_branch)
      end
      it "should delete a branch" do
        clone_config = get_clone_config("GitHub", @project[:projectname])
        repository_id, _ = clone_repo(@project[:id], clone_config)
        test_branch = "test_branch"
        create_branch(@project[:id], repository_id, test_branch)
        delete_branch(@project[:id], repository_id, test_branch)
        wait_for_git_operation_completed(@project[:id], repository_id, json_body[:id], "Success")
        get_branch_commits(@project[:id], repository_id, test_branch)
        expect(json_body[:count]).to be == 0
      end
      it "should checkout to a branch after create" do
        clone_config = get_clone_config("GitHub", @project[:projectname])
        repository_id, _ = clone_repo(@project[:id], clone_config)
        create_branch(@project[:id], repository_id, "test_branch")
        checkout_branch(@project[:id], repository_id, "test_branch")
      end
      it "should create branch and checkout at same time" do
        clone_config = get_clone_config("GitHub", @project[:projectname])
        repository_id, _ = clone_repo(@project[:id], clone_config)
        test_branch = "test_branch"
        create_checkout_branch(@project[:id], repository_id, test_branch)
        expect_status_details(200)
        #wait for the checkout operation to complete
        wait_for_git_operation_completed(@project[:id], repository_id, json_body[:id], "Success")
        get_repository(@project[:id], repository_id)
        expect_status_details(200)
        expect(json_body[:currentBranch]).to be == test_branch
      end
      it "should checkout to a commit" do
        clone_config = get_clone_config("GitHub", @project[:projectname])
        repository_id, _ = clone_repo(@project[:id], clone_config)
        get_repository(@project[:id], repository_id)
        expect_status_details(200)
        current_branch = json_body[:currentBranch]
        get_branch_commits(@project[:id], repository_id, current_branch)
        expect_status_details(200)
        expect(json_body[:count]).to be > 1
        commit = json_body[:items][1][:commitHash]
        checkout_commit(@project[:id], repository_id, commit)
        expect_status_details(200)
        wait_for_git_operation_completed(@project[:id], repository_id, json_body[:id], "Success")
        get_repository(@project[:id], repository_id)
        expect_status_details(200)
        latest_branch = json_body[:currentBranch]
        latest_commit = json_body[:currentCommit][:commitHash]
        expect(latest_branch).to be == "HEAD" #in detached mode
        expect(latest_commit).to be == commit
      end
      it "should return added file on git status" do
        clone_config = get_clone_config("GitHub", @project[:projectname])
        repository_id, repository_path = clone_repo(@project[:id], clone_config)
        git_file_add_or_delete(@project, repository_id, repository_path, "Sample.json", "add")
      end
      it "should create a commit" do
        clone_config = get_clone_config("GitHub", @project[:projectname])
        repository_id, _ = clone_repo(@project[:id], clone_config)
        make_commit_in_repo(@project, repository_id)
      end
      it "should checkout a file" do
        clone_config = get_clone_config("GitHub", @project[:projectname])
        repository_id, repository_path = clone_repo(@project[:id], clone_config)
        filename = "Sample.json"
        #add the file
        git_file_add_or_delete(@project, repository_id, repository_path, filename, "add")
        #make commit
        commit_config = {
          type: "commitCommandConfiguration",
          all:true,
          message: "Test commit",
          files: []
        }
        git_commit(@project[:id], repository_id, commit_config.to_json)
        expect_status_details(200)
        wait_for_git_operation_completed(@project[:id], repository_id, json_body[:id], "Success")
        #delete the file
        git_file_add_or_delete(@project, repository_id, repository_path, filename, "delete")
        #do git checkout filename
        checkout_command_config = {
          files:[filename]
        }
        checkout_files(@project[:id], repository_id, checkout_command_config.to_json)
        expect_status_details(200)
        wait_for_git_operation_completed(@project[:id], repository_id, json_body[:id], "Success")
        #do git status
        git_status(@project[:id], repository_id)
        expect_status_details(200)
        wait_for_git_operation_completed(@project[:id], repository_id, json_body[:id], "Success")
        get_git_execution_object(@project[:id], repository_id, json_body[:id])
        expect_status_details(200)
        new_status = JSON.parse(json_body[:commandResultMessage])
        expect(new_status[:status]).to be_nil
      end
      it "should do git pull" do
        clone_config = get_clone_config("GitHub", @project[:projectname])
        repository_id, _ = clone_repo(@project[:id], clone_config)
        create_branch(@project[:id], repository_id, "test_branch")
        checkout_branch(@project[:id], repository_id, "test_branch")
        make_commit_in_repo(@project, repository_id)
        git_pull(@project[:id], repository_id, remote_name="origin", branch_name="test_branch")
        wait_for_git_operation_completed(@project[:id], repository_id, json_body[:id], "Success")
      end
      it 'should get all repository remotes' do
        clone_config = get_clone_config("GitHub", @project[:projectname])
        repository_id, _ = clone_repo(@project[:id], clone_config)
        get_remotes(@project[:id], repository_id)
        expect_status_details(200)
        expect(json_body[:count]).to be > 0
      end
      it 'should add a git remote' do
        clone_config = get_clone_config("GitHub", @project[:projectname])
        repository_id, repository_path = clone_repo(@project[:id], clone_config)
        test_remote_name = "test_remote"
        test_remote_url = "https://github.com/logicalclocks/hopsworks-ee.git"
        add_remote(@project[:id], repository_id, test_remote_name, test_remote_url)
        expect_status_details(200)
        wait_for_git_operation_completed(@project[:id], repository_id, json_body[:id], "Success")
        get_remotes(@project[:id], repository_id)
        expect_status_details(200)
        expect(json_body[:count]).to be > 1
        remotes = json_body[:items]
        added = false
        remotes.each do |remote|
          if remote[:remoteName] == test_remote_name
            added = true
            break
          end
        end
        expect(added).to be true
      end
    end
    describe 'Read only repositories' do
      before(:all) do
        setVar("enable_read_only_git_repositories", "true")
        create_session(@project[:username], "Pass123")
      end
      after(:all) do
        setVar("enable_read_only_git_repositories", "false")
        create_session(@project[:username], "Pass123")
      end
      describe "Read only enabled at cluster level" do
        it 'should create a read only repository by default' do
          dir_name = "/Projects/#{@project[:projectname]}/Jupyter/testDir#{short_random_id}"
          create_dir(@project, dir_name, query: "&type=DATASET")
          expect_status_details(201)
          clone_config = get_clone_config("GitHub", @project[:projectname], url="", branch="", dir_name)
          repo_id, repo_path = clone_repo(@project[:id], clone_config)
          expect(repo_id).not_to be_nil
          expect(repo_path).not_to be_nil
          get_repository(@project[:id], repo_id)
          expect_status_details(200)
          expect(json_body[:readOnly]).to be == true
          delete_repository(@project[:id], repo_id)
        end
      end
      describe "Operation on read only repositories" do
        it 'should fail to commit in a read only repository' do
          dir_name = "/Projects/#{@project[:projectname]}/Jupyter/testDir#{short_random_id}"
          create_dir(@project, dir_name, query: "&type=DATASET")
          expect_status_details(201)
          clone_config = get_clone_config("GitHub", @project[:projectname], url="", branch="", dir_name)
          repo_id, repo_path = clone_repo(@project[:id], clone_config)
          expect(repo_id).not_to be_nil
          expect(repo_path).not_to be_nil
          #make commit
          commit_message = "Rspec Test commit"
          commit_config = {
            type: "commitCommandConfiguration",
            all:true,
            message: commit_message,
            files: []
          }
          git_commit(@project[:id], repo_id, commit_config.to_json)
          expect_status_details(400, error_code: 500036)
          delete_repository(@project[:id], repo_id)
        end
        it 'should fail to checkout a file in a read only repository' do
          dir_name = "/Projects/#{@project[:projectname]}/Jupyter/testDir#{short_random_id}"
          create_dir(@project, dir_name, query: "&type=DATASET")
          expect_status_details(201)
          clone_config = get_clone_config("GitHub", @project[:projectname], url="", branch="", dir_name)
          repo_id, repo_path = clone_repo(@project[:id], clone_config)
          expect(repo_id).not_to be_nil
          expect(repo_path).not_to be_nil
          #do git checkout filename
          checkout_command_config = {
            files:["test.txt"]
          }
          checkout_files(@project[:id], repo_id, checkout_command_config.to_json)
          expect_status_details(400, error_code: 500036)
          delete_repository(@project[:id], repo_id)
        end
      end
    end
    describe "Operation on big repositories" do
      it "should be able to clone big repositories" do
        clone_config = get_clone_config("GitHub", @project[:projectname], url="https://github.com/logicalclocks/hops-examples.git")
        repoId, _ = clone_repo(@project[:id], clone_config, big_repo=true)
        delete_repository(@project[:id], repoId)
      end
    end
    describe "Git operation" do
      after :each do
        setVar("git_command_timeout_minutes", 15)
        create_session(@project[:username], "Pass123")
      end
      it "should indicate ongoing operation in the repository" do
        begin
          clone_config = get_clone_config("GitHub", @project[:projectname])
          do_clone_git_repo(@project[:id], clone_config)
          expect_status_details(200)
          repository_id = json_body[:repository][:id]
          execution_id = json_body[:id]
          get_repository(@project[:id], repository_id)
          expect_status_details(200)
          expect(json_body[:ongoingOperation]).not_to be_nil
          wait_for_git_operation_completed(@project[:id], repository_id, execution_id, "Success")
        ensure
          delete_repository(@project[:id], repository_id)
        end
      end
      it "should not allow two operations at same time in the same repository" do
        begin
          clone_config = get_clone_config("GitHub", @project[:projectname])
          repository_id, repository_path = clone_repo(@project[:id], clone_config)
          git_status(@project[:id], repository_id)
          expect_status_details(200)
          execution_id = json_body[:id]
          get_repository(@project[:id], repository_id)
          expect_status_details(200)
          #do another operation without waiting
          git_status(@project[:id], repository_id)
          expect(json_body[:errorCode]).to be == 500027
          wait_for_git_operation_completed(@project[:id], repository_id, execution_id, "Success")
        ensure
          delete_repository(@project[:id], repository_id)
        end
      end
      it "should be killed by timer" do
        begin
          setVar("git_command_timeout_minutes", 1)
          create_session(@project[:username], "Pass123")
          #Try cloning a big repository - will take more than a minute
          clone_config = get_clone_config("GitHub", @project[:projectname], url = "https://github.com/tensorflow/tensorflow.git")
          do_clone_git_repo(@project[:id], clone_config)
          expect_status_details(200)
          repository_id = json_body[:repository][:id]
          execution_id = json_body[:id]
          get_repository(@project[:id], repository_id)
          expect_status_details(200)
          wait_for_git_op do
            get_git_execution_object(@project[:id], repository_id, execution_id)
            json_body[:state] == "Timedout"
          end
        ensure
          delete_repository(@project[:id], repository_id)
        end
      end
      it 'should cancel a git execution' do
        begin
          clone_config = get_clone_config("GitHub", @project[:projectname])
          repository_id, _ = clone_repo(@project[:id], clone_config)
          git_status(@project[:id], repository_id)
          expect_status_details(200)
          execution_id = json_body[:id]
          # cancel the execution
          cancel_git_execution(@project[:id],  repository_id, execution_id)
          expect_status_details(200)
          wait_for_git_operation_completed(@project[:id], repository_id, execution_id, "Cancelled")
        ensure
          delete_repository(@project[:id], repository_id)
        end
      end
    end
  end
end
