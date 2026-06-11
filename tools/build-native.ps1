$ErrorActionPreference = 'Stop'

$RepoRoot = Resolve-Path (Join-Path $PSScriptRoot '..')
$NativeSource = Join-Path $RepoRoot 'native\fixics_physics'
$NativeBuild = Join-Path $NativeSource 'build'
$OutputDll = Join-Path $RepoRoot 'FIXICSPhysics_x64.dll'

$VsWhere = Join-Path ${env:ProgramFiles(x86)} 'Microsoft Visual Studio\Installer\vswhere.exe'
if (-not (Test-Path -LiteralPath $VsWhere)) {
    throw 'vswhere.exe was not found. Install Visual Studio Build Tools 2022 with the C++ build tools workload.'
}

$VsInstall = & $VsWhere -latest -products * -requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64 -property installationPath
if (-not $VsInstall) {
    throw 'Visual Studio Build Tools with VC x64 tools was not found.'
}

$VsDevCmd = Join-Path $VsInstall 'Common7\Tools\VsDevCmd.bat'
if (-not (Test-Path -LiteralPath $VsDevCmd)) {
    throw "VsDevCmd.bat was not found at $VsDevCmd."
}

$BuildCommand = @(
    "`"$VsDevCmd`" -arch=x64",
    "cmake -S `"$NativeSource`" -B `"$NativeBuild`" -A x64",
    "cmake --build `"$NativeBuild`" --config Release",
    "ctest --test-dir `"$NativeBuild`" -C Release --output-on-failure"
) -join ' && '

try {
    cmd.exe /d /s /c $BuildCommand
    if ($LASTEXITCODE -ne 0) {
        exit $LASTEXITCODE
    }

    if (-not (Test-Path -LiteralPath $OutputDll)) {
        throw "Native build completed but FIXICSPhysics_x64.dll was not found at $OutputDll."
    }

    Write-Host "Built $OutputDll"
}
finally {
    if (Test-Path -LiteralPath $NativeBuild) {
        $ResolvedNativeSource = (Resolve-Path -LiteralPath $NativeSource).Path
        $ResolvedNativeBuild = (Resolve-Path -LiteralPath $NativeBuild).Path
        $ExpectedNativeBuild = [IO.Path]::GetFullPath((Join-Path $ResolvedNativeSource 'build'))

        if ($ResolvedNativeBuild -ne $ExpectedNativeBuild) {
            throw "Refusing to clean unexpected native build path: $ResolvedNativeBuild"
        }

        Remove-Item -LiteralPath $ResolvedNativeBuild -Recurse -Force
    }
}
