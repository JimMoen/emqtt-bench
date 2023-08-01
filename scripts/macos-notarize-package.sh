#!/usr/bin/env bash

set -euo pipefail

# intended to run on MacOS only
if [ $(uname) != 'Darwin' ]; then
    echo 'Not macOS, exiting';
    exit 0;
fi

pushd "${RELX_TEMP_DIR}"

ZIP_PACKAGE_PATH="${1:-${RELX_OUTPUT_DIR}/${RELX_RELEASE_NAME}-${RELX_RELEASE_VSN}.zip}"
zip -qr "${ZIP_PACKAGE_PATH}" .

popd

if [[ "${APPLE_ID:-0}" == 0 || "${APPLE_ID_PASSWORD:-0}" == 0 || "${APPLE_TEAM_ID:-0}" == 0 ]]; then
    echo "Apple ID is not configured, skipping notarization."
    exit 0
fi

# notarize the package
# if fails, check what went wrong with this command:
# xcrun notarytool log \
    #   --apple-id "${APPLE_ID}" \
    #   --password "${APPLE_ID_PASSWORD}" \
    #   --team-id "${APPLE_TEAM_ID}" <submission-id>
echo 'Submitting the package for notarization to Apple (normally takes about a minute)'
notarytool_output="$(xcrun notarytool submit \
                                           --apple-id "${APPLE_ID}" \
                                           --password "${APPLE_ID_PASSWORD}" \
                                           --team-id "${APPLE_TEAM_ID}" "${ZIP_PACKAGE_PATH}" \
                                           --no-progress \
                                           --wait)"
echo "$notarytool_output"
echo "$notarytool_output" | grep -q 'status: Accepted' || {
    echo 'Notarization failed';
    exit 1;
}

