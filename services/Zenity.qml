import QtQuick
import Quickshell
import qs.services

pragma Singleton

// A global singleton service for selecting files/folders via Zenity through the XDG portal.
// This service lives for the entire lifecycle of Quickshell, preventing garbage collection
// or object destruction when individual Settings pages or panels are closed.
Singleton {
    id: root

    function selectFile(filters, callback) {
        var args = ["zenity", "--file-selection", "--title=Select File"];

        // Convert Qt filter format "Label (*.ext1 *.ext2)" → zenity format "Label | *.ext1 *.ext2"
        if (filters && filters.length > 0) {
            var match = filters[0].match(/^(.*?)\s*\((.*)\)$/);
            if (match) {
                args.push("--file-filter=" + match[1].trim() + " | " + match[2]);
            }
        }

        ProcessService.run(args, function(stdout, exitCode) {
            if (exitCode === 0) {
                var path = stdout.trim();
                if (path !== "" && callback) {
                    callback(path);
                }
            }
        });
    }

    function selectFolder(callback) {
        ProcessService.run(
            ["zenity", "--file-selection", "--directory", "--title=Select Folder"],
            function(stdout, exitCode) {
                if (exitCode === 0) {
                    var path = stdout.trim();
                    if (path !== "" && callback) {
                        callback(path);
                    }
                }
            }
        );
    }
}
