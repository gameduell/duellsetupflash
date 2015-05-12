/*
 * Copyright (c) 2003-2015, GameDuell GmbH
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 *
 * 1. Redistributions of source code must retain the above copyright notice,
 * this list of conditions and the following disclaimer.
 *
 * 2. Redistributions in binary form must reproduce the above copyright notice,
 * this list of conditions and the following disclaimer in the documentation
 * and/or other materials provided with the distribution.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
 * ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 * WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
 * IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY
 * DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
 * LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
 * ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 * SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

package duell.setup.plugin;

import duell.helpers.PlatformHelper;
import duell.helpers.AskHelper;
import duell.helpers.DownloadHelper;
import duell.helpers.ExtractionHelper;
import duell.helpers.PathHelper;
import duell.helpers.LogHelper;
import duell.helpers.StringHelper;
import duell.helpers.CommandHelper;
import duell.helpers.HXCPPConfigXMLHelper;
import duell.helpers.DuellConfigHelper;

import duell.objects.HXCPPConfigXML;

import haxe.io.Path;
import sys.FileSystem;

using StringTools;

class EnvironmentSetup
{
    private static var airMacPath = "http://airdownload.adobe.com/air/mac/download/latest/AIRSDK_Compiler.tbz2";
    private static var airWindowsPath = "http://airdownload.adobe.com/air/win/download/latest/AIRSDK_Compiler.zip";
    private static var flashDebuggerMacPath = "http://fpdownload.macromedia.com/pub/flashplayer/updaters/14/flashplayer_14_sa.dmg";
    private static var flashDebuggerWindowsPath = "http://download.macromedia.com/pub/flashplayer/updaters/14/flashplayer_14_sa.exe";
    private static var flashPlayerSystemPluginPath = "http://get.adobe.com/flashplayer/otherversions/";

/// RESULTING VARIABLES
    private var airSDKPath : String = null;
    private var hxcppConfigPath : String = null;

    public function new()
    {

    }

    public function setup() : String
    {
        LogHelper.info("");
        LogHelper.info("\x1b[2m------");
        LogHelper.info("Flash Setup");
        LogHelper.info("------\x1b[0m");
        LogHelper.info("");

        downloadAirSDK();

        LogHelper.println("");

        LogHelper.println("Installing the air haxelib...");

        var haxePath = Sys.getEnv("HAXEPATH");
        var systemCommand = haxePath != null && haxePath != "" ? false : true;
        CommandHelper.runCommand(haxePath, "haxelib", ["install", "air3"], {systemCommand: systemCommand, errorMessage: "installing air3 library"});

        LogHelper.println("");

        downloadFlashPlayer();

        LogHelper.println("");

        setupHXCPP();

        LogHelper.info("\x1b[2m------");
        LogHelper.info("end");
        LogHelper.info("------\x1b[0m");

        return "success";
    }

    private function downloadAirSDK()
    {

        /// variable setup
        var downloadPath = "";
        var defaultInstallPath = "";

        defaultInstallPath = haxe.io.Path.join([DuellConfigHelper.getDuellConfigFolderLocation(), "SDKs", "adobeair"]);

        if (PlatformHelper.hostPlatform == Platform.WINDOWS)
        {
            downloadPath = airWindowsPath;
        }
        else if (PlatformHelper.hostPlatform == Platform.MAC)
        {
            downloadPath = airMacPath;
        }

        var downloadAnswer = AskHelper.askYesOrNo("Download and install the Adobe AIR SDK?");

        /// ask for the instalation path
        airSDKPath = AskHelper.askString("Air SDK Location", defaultInstallPath);

        /// clean up a bit
        airSDKPath = airSDKPath.trim();

        if(airSDKPath == "")
            airSDKPath = defaultInstallPath;

        airSDKPath = resolvePath(airSDKPath);

        if(downloadAnswer)
        {
            /// the actual download
            DownloadHelper.downloadFile(downloadPath);

            /// create the directory
            PathHelper.mkdir(airSDKPath);

            /// the extraction
            ExtractionHelper.extractFile(Path.withoutDirectory(downloadPath), airSDKPath, "");
        }
    }

    private function downloadFlashPlayer()
    {
        var answer = AskHelper.askYesOrNo("Go to the flash website and download the Flash Player System plugin?");

        if(answer)
        {
            CommandHelper.openURL(flashPlayerSystemPluginPath);
        }
    }

    private function setupHXCPP()
    {
        hxcppConfigPath = HXCPPConfigXMLHelper.getProbableHXCPPConfigLocation();

        if(hxcppConfigPath == null)
        {
            throw "Could not find the home folder, no HOME variable is set. Can't find hxcpp_config.xml";
        }

        var hxcppXML = HXCPPConfigXML.getConfig(hxcppConfigPath);

        var existingDefines : Map<String, String> = hxcppXML.getDefines();

        var newDefines : Map<String, String> = getDefinesToWriteToHXCPP();

        LogHelper.println("\x1b[1mWriting new definitions to hxcpp config file\x1b[0m");

        for(def in newDefines.keys())
        {
            LogHelper.info("\x1b[1m        " + def + "\x1b[0m:" + newDefines.get(def));
        }

        for(def in existingDefines.keys())
        {
            if(!newDefines.exists(def))
            {
                newDefines.set(def, existingDefines.get(def));
            }
        }

        hxcppXML.writeDefines(newDefines);
    }

    private function getDefinesToWriteToHXCPP() : Map<String, String>
    {
        var defines = new Map<String, String>();

        if(FileSystem.exists(airSDKPath))
        {
            defines.set("AIR_SDK", FileSystem.fullPath(airSDKPath));
        }
        else
        {
            throw "Path specified for air SDK doesn't exist!";
        }

        defines.set("AIR_SETUP", "YES");

        return defines;
    }


    private function resolvePath(path : String) : String
    {
        path = PathHelper.unescape(path);

        if (PathHelper.isPathRooted(path))
            return path;

        return Path.join([Sys.getCwd(), path]);
    }
}
