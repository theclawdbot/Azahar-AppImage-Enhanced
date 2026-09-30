#!/bin/sh

set -eu

ARCH=$(uname -m)
export ARCH
export OUTPATH=./dist
export ADD_HOOKS="self-updater.hook:x86-64-v3-check.hook"
RELEASE_TAG="${APPIMAGE_RELEASE_TAG:-latest}"
export UPINFO="gh-releases-zsync|${GITHUB_REPOSITORY%/*}|${GITHUB_REPOSITORY#*/}|$RELEASE_TAG|*$ARCH.AppImage.zsync"
export APPNAME=Azahar
export DESKTOP=/usr/share/applications/org.azahar_emu.Azahar.desktop
export ICON=/usr/share/icons/hicolor/512x512/apps/org.azahar_emu.Azahar.png
export DEPLOY_OPENGL=1
# Keep Mesa/Turnip on the host. Bundling a Freedreno ICD makes Sharun prefer
# the AppImage driver over Armada's native driver, and that bundled driver's
# VK_KHR_display event path crashes after successful presents.
export DEPLOY_VULKAN=0
export DEPLOY_PIPEWIRE=1

# Deploy dependencies
quick-sharun /usr/bin/azahar* /usr/lib/libgamemode.so*

# The strace pass can still discover Vulkan ICDs loaded during startup. Remove
# driver and layer payloads while retaining libvulkan.so (the Khronos loader)
# and the bundled OpenGL/Gallium stack.
rm -f AppDir/lib/libvulkan_*.so* AppDir/lib/libVkLayer_*.so*
rm -rf AppDir/share/vulkan/icd.d AppDir/share/vulkan/explicit_layer.d \
       AppDir/share/vulkan/implicit_layer.d

# With no bundled ICD directory, publish the host ICD directories to the
# loader. Sharun sources executable hooks from AppDir/bin at runtime.
cat > AppDir/bin/06-host-vulkan-icd.hook <<'EOF'
#!/bin/sh
export SHARUN_ALLOW_SYS_VKICD="${SHARUN_ALLOW_SYS_VKICD:-1}"
EOF
chmod 0755 AppDir/bin/06-host-vulkan-icd.hook

# Additional changes can be done in between here

# Turn AppDir into AppImage
quick-sharun --make-appimage
