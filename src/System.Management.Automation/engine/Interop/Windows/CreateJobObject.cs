// Copyright (c) Microsoft Corporation.
// Licensed under the MIT License.

#nullable enable

using System.Runtime.InteropServices;

internal static partial class Interop
{
    internal static partial class Windows
    {
        [LibraryImport("api-ms-win-core-job-l2-1-0.dll", EntryPoint = "CreateJobObjectW", SetLastError = true)]
        internal static partial nint CreateJobObject(
            nint lpJobAttributes,
            nint lpName);
    }
}