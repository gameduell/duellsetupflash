package duell.setup.plugin;

import duell.helpers.PlatformHelper;
import duell.helpers.AskHelper;
import duell.helpers.DownloadHelper;
import duell.helpers.ExtractionHelper;
import duell.helpers.PathHelper;
import duell.helpers.LogHelper;
import duell.helpers.StringHelper;
import duell.helpers.ProcessHelper;
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

    public function setup(args : Array<String>) : String
    {
        try
        {
            LogHelper.info("");
            LogHelper.info("\x1b[2m------");
            LogHelper.info("Flash Setup");
            LogHelper.info("------\x1b[0m");
            LogHelper.info("");

            downloadAirSDK();

            LogHelper.println("");

            LogHelper.println("Installing the air haxelib...");
            ProcessHelper.runCommand ("", "haxelib", [ "install", "air3" ], true, true);

            LogHelper.println("");

            downloadFlashPlayer();

            LogHelper.println("");

            downloadFlashDebugger();

            LogHelper.println("");

            setupHXCPP();

            LogHelper.info("\x1b[2m------");
            LogHelper.info("end");
            LogHelper.info("------\x1b[0m");

        } catch(error : Dynamic)
        {
            LogHelper.error("An error occurred, do you need admin permissions to run the script? Check if you have permissions to write on the paths you specify. Error:" + error);
        }

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

    private function downloadFlashDebugger()
    {
        /// variable setup
        var downloadPath = "";
        var defaultInstallPath = "";

        if(PlatformHelper.hostPlatform == Platform.WINDOWS)
        {
            downloadPath = flashDebuggerWindowsPath;
        }
        else if(PlatformHelper.hostPlatform == Platform.MAC)
        {
            downloadPath = flashDebuggerMacPath;
        }

        var downloadAnswer = AskHelper.askYesOrNo("Download and install the Flash Debugger?");

        if(downloadAnswer)
        {
            /// the actual download
            DownloadHelper.downloadFile(downloadPath);

            LogHelper.info("Running installer " + Path.withoutDirectory(downloadPath));
            // running the installer
            ProcessHelper.runInstaller(Path.withoutDirectory(downloadPath));
        }

        LogHelper.println("You additionally need to associate .swf files with the debugger.");
    }

    private function downloadFlashPlayer()
    {
        var answer = AskHelper.askYesOrNo("Go to the flash website and download the Flash Player System plugin?");

        if(answer)
        {
            ProcessHelper.openURL(flashPlayerSystemPluginPath);
        }
    }

    private function setupHXCPP()
    {
        hxcppConfigPath = HXCPPConfigXMLHelper.getProbableHXCPPConfigLocation();

        if(hxcppConfigPath == null)
        {
            LogHelper.error("Could not find the home folder, no HOME variable is set. Can't find hxcpp_config.xml");
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
            LogHelper.error("Path specified for air SDK doesn't exist!");
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