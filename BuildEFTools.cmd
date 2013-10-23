<?xml version="1.0" encoding="utf-8"?>
<Project ToolsVersion="4.0" DefaultTargets="Test" xmlns="http://schemas.microsoft.com/developer/msbuild/2003">
    <PropertyGroup>
        <Configuration Condition=" '$(Configuration)' == '' ">Debug</Configuration>
        <Platform Condition=" '$(Platform)' == '' ">AnyCPU</Platform>
        <BuildProperties>Platform=$(Platform);RestorePackages=false</BuildProperties>
        <VSTest>$(VSINSTALLDIR)\Common7\IDE\CommonExtensions\Microsoft\TestWindow\vstest.console.exe</VSTest>
        <BuildTargets>Build</BuildTargets>
        <SolutionDir Condition="$(SolutionDir) == '' Or $(SolutionDir) == '*Undefined*'">$(MSBuildThisFileDirectory)</SolutionDir>
        <SkipEnvSetup></SkipEnvSetup>
        <LogsDir>$(SolutionDir)logs\</LogsDir>
    </PropertyGroup>

    <ItemGroup>
        <Projects Include="$(SolutionDir)src\EntityFramework\EntityFramework.csproj" />
        <Projects Include="$(SolutionDir)src\EntityFramework.SqlServer\EntityFramework.SqlServer.csproj" />
        <Projects Include="$(SolutionDir)src\EntityFramework.SqlServerCompact\EntityFramework.SqlServerCompact.csproj" />
        <Projects Include="$(SolutionDir)src\EFTools\XmlCore\XmlCore.csproj" />
        <Projects Include="$(SolutionDir)src\EFTools\DesignXmlCore\DesignXmlCore.csproj" />
        <Projects Include="$(SolutionDir)src\EFTools\EntityDesignModel\EntityDesignModel.csproj" />
        <Projects Include="$(SolutionDir)src\EFTools\EntityDesign\EntityDesign.csproj" />
        <Projects Include="$(SolutionDir)src\EFTools\EntityDesignBootstrapPackage\EntityDesignBootstrapPackage.csproj" />
        <Projects Include="$(SolutionDir)src\EFTools\EntityDesignDatabaseGeneration\EntityDesignDatabaseGeneration.csproj" />
        <Projects Condition="$(VisualStudioVersion)=='11.0'" Include="$(SolutionDir)src\EFTools\EntityDesignDataSourceWizardExtension\EntityDesignDataSourceWizardExtension.csproj" />
        <Projects Include="$(SolutionDir)src\EFTools\EntityDesignEntityDesigner\EntityDesigner.csproj" />
        <Projects Include="$(SolutionDir)src\EFTools\EntityDesignExtensibility\EntityDesignExtensibility.csproj" />
        <Projects Include="$(SolutionDir)src\EFTools\EntityDesignPackage\EntityDesignPackage.csproj" />
        <Projects Include="$(SolutionDir)src\EFTools\EntityDesignerVersioningFacade\EntityDesignerVersioningFacade.csproj" />
        <Projects Include="$(SolutionDir)test\EFTools\InProcTests\InProcTests.csproj" />
        <Projects Include="$(SolutionDir)test\EFTools\FunctionalTests\FunctionalTests.csproj" />
        <Projects Include="$(SolutionDir)test\EFTools\TestInfrastructure\TestInfrastructure.csproj" />
        <Projects Include="$(SolutionDir)test\EFTools\UnitTests\UnitTests.csproj" />
        <Projects Include="$(SolutionDir)tools\VsIdeHostAdapter\Framework\VsIdeTestHostFramework.csproj" />
    </ItemGroup>

    <Import Project="$(SolutionDir)\tools\EFTools.common.targets" />
    <Import Project="$(SolutionDir)\.nuget\nuget.targets" />

    <Target Name="Clean">
        <MSBuild Targets="Clean"
                 Projects="@(Projects)" />
        <MSBuild Targets="Clean"
                 Projects="$(SolutionDir)\setup\dirs.proj" />
    </Target>

    <Target Name="Scorch">
        <MSBuild Targets="SafeGitClean"
                 Projects="$(MSBuildProjectFile)"
                 Properties="BackupDir=$(SolutionDir)\ScorchSave\;DeleteBackupDir=true" />
    </Target>

    <Target Name="CreateDirectories">
        <MakeDir Directories="$(LogsDir)"/>
    </Target>

    <Target Name="RestorePackages">
        <PropertyGroup>
            <RequireRestoreConsent>false</RequireRestoreConsent>
        </PropertyGroup>
        <ItemGroup>
            <RestoreProjFiles Include="$(SolutionDir)\test\EFTools\FunctionalTests\*.csproj" />
            <RestoreProjFiles Include="$(SolutionDir)\test\EFTools\UnitTests\*.csproj" />
        </ItemGroup>
        <Message Text="Restoring NuGet packages..." Importance="High" />
        <MSBuild Projects="@(RestoreProjFiles)" Targets="RestorePackages" Properties="RequireRestoreConsent=$(RequireRestoreConsent)" />
    </Target>

    <Target Name="RestoreSolutionPackages" DependsOnTargets="CheckPrerequisites" AfterTargets="RestorePackages">
        <PropertyGroup>
            <PackagesConfig>$([System.IO.Path]::Combine($(NuGetToolsPath), "packages.config"))</PackagesConfig>
            <SolutionRequireConsentSwitch Condition=" $(RequireRestoreConsent) == 'true' ">-RequireConsent</SolutionRequireConsentSwitch>
            <RestoreCommand>$(NuGetCommand) install "$(PackagesConfig)" -source "$(PackageSources)"  $(SolutionRequireConsentSwitch) -solutionDir "$(SolutionDir) "</RestoreCommand>
        </PropertyGroup>
        <Exec Command="$(RestoreCommand)"
              LogStandardErrorAsError="true" />
    </Target>

    <Target Name="CheckSkipStrongNames" DependsOnTargets="RestoreSolutionPackages">
        <MSBuild Targets="CheckSkipStrongNames"
                 Projects="$(SolutionDir)\tools\EFTools.skipstrongnames.targets" />
    </Target>

    <Target Name="EnableSkipStrongNames" DependsOnTargets="RestoreSolutionPackages">
        <MSBuild Targets="EnableSkipStrongNames"
                 Projects="$(SolutionDir)\tools\EFTools.skipstrongnames.targets" />
    </Target>

    <Target Name="DisableSkipStrongNames" DependsOnTargets="RestoreSolutionPackages">
        <MSBuild Targets="DisableSkipStrongNames"
                 Projects="$(SolutionDir)\tools\EFTools.skipstrongnames.targets" />
    </Target>


    <Target Name="BuildDesigner">
        <MSBuild Targets="$(BuildTargets)"
                   Projects="@(Projects)"
                   Properties="Configuration=$(Configuration);$(BuildProperties);BuildPackages=false" />
    </Target>

    <Target Name="BuildInstaller">
        <MSBuild Targets="$(BuildTargets)"
             Projects="$(SolutionDir)src\EFTools\setup\EFToolsMsi\EFToolsMsi.wixproj"
             BuildInParallel="false"
             Properties="Configuration=$(Configuration);$(BuildProperties);BuildPackages=false" />
    </Target>

    <Target Name="Build" DependsOnTargets="CreateDirectories;CheckSkipStrongNames;RestorePackages;BuildDesigner;BuildInstaller" />

    <Target Name="Rebuild">
        <MSBuild Projects="$(MSBuildProjectFile)" Properties="BuildTargets=Rebuild;Configuration=$(Configuration)" Targets="Build" />
    </Target>

    <Target Name="InstallTestHost" DependsOnTargets="CreateDirectories">
        <PropertyGroup>
            <TestHostPath>HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\{D39AE4C3-21C4-40DE-9F35-53A83803F8DB}</TestHostPath>
            <TestHostPath Condition="$(VisualStudioVersion)=='11.0'">HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\{710EEA0D-C40D-4245-B3FA-C883AAD83A65}</TestHostPath>
            <TestHostQuery>$([MSBuild]::GetRegistryValueFromView('$(TestHostPath)', 'DisplayName', null, RegistryView.Registry64, RegistryView.Registry32))</TestHostQuery>
            <TestHostInstalled>$(TestHostQuery.StartsWith('VS IDE Test Host for Visual Studio'))</TestHostInstalled>
        </PropertyGroup>
        <MSBuild Condition="'$(TestHostInstalled)'!='True'"
                 Targets="Clean;Build"
                 Projects="$(SolutionDir)\tools\VsIdeHostAdapter\dirs.proj"
                 Properties="Configuration=$(Configuration)" />
        <Exec Condition="'$(TestHostInstalled)'!='True'"
              Command='msiexec /qb /i $(SolutionDir)\bin\$(Configuration)\VsIdeTestHost.msi /L*v $(LogsDir)VsIdeTestHost.msi.log'
              IgnoreExitCode='true' />
    </Target>

    <Target Name="Install" DependsOnTargets="Rebuild">
        <Exec Command='msiexec /qb /i $(SolutionDir)\bin\$(Configuration)\en\EFTools.msi SKIPENVIRONMENTSETUP="$(SkipEnvSetup)" /L*v $(LogsDir)EFTools.msi.log' />
    </Target>

    <Target Name="Test" DependsOnTargets="Install;InstallTestHost">
        <MSBuild Projects="$(SolutionDir)tools\EFTools.xunit.targets"
                 Properties="Configuration=$(Configuration);$(BuildProperties)" />
        <Exec Condition="'$(TestCaseFilter)'!=''" Command='"$(VSTest)" EFDesigner.InProcTests.dll /Settings:..\..\EFDesignerInProcTests.testsettings /InIsolation /logger:trx /TestCaseFilter:$(TestCaseFilter)'
              WorkingDirectory="$(SolutionDir)test\EFTools\InProcTests\bin\$(Configuration)\"/>
	      <Exec Condition="'$(TestCaseFilter)'==''" Command='"$(VSTest)" EFDesigner.InProcTests.dll /Settings:..\..\EFDesignerInProcTests.testsettings /InIsolation /logger:trx'
              WorkingDirectory="$(SolutionDir)test\EFTools\InProcTests\bin\$(Configuration)\"/>
    </Target>

    <Target Name="ReRunTests">
        <MSBuild Targets="$(BuildTargets)"
                 Projects="$(MSBuildThisFileDirectory)test\EFTools\dirs.proj"
                 Properties="Configuration=$(Configuration);BuildPackages=false" />
        <MSBuild Projects="$(SolutionDir)tools\EFTools.xunit.targets"
                 Properties="Configuration=$(Configuration);$(BuildProperties)" />
        <Exec Command='"$(VSTest)" EFDesigner.InProcTests.dll /Settings:..\..\EFDesignerInProcTests.testsettings /InIsolation /logger:trx /TestCaseFilter:"TestCategory!=DoNotRunOnCI"'
              WorkingDirectory="$(SolutionDir)test\EFTools\InProcTests\bin\$(Configuration)\"/>
    </Target>

</Project>