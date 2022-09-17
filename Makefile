TARGET_CODESIGN = $(shell which ldid)

POGOTMP = $(TMPDIR)/pogo
POGO_STAGE_DIR = $(POGOTMP)/stage
POGO_APP_DIR 	= $(POGOTMP)/Build/Products/Release-iphoneos/Pogo.app
POGO_HELPER_PATH 	= $(POGOTMP)/Build/Products/Release-iphoneos/PogoHelper

package: 
	@set -o pipefail; \
		xcodebuild -jobs $(shell sysctl -n hw.ncpu) -project 'Pogo.xcodeproj' -scheme Pogo -configuration Release -arch arm64 -sdk iphoneos -derivedDataPath $(POGOTMP) \
		CODE_SIGNING_ALLOWED=NO DSTROOT=$(POGOTMP)/install ALWAYS_EMBED_SWIFT_STANDARD_LIBRARIES=NO
	@set -o pipefail; \
		xcodebuild -jobs $(shell sysctl -n hw.ncpu) -project 'Pogo.xcodeproj' -scheme PogoHelper -configuration Release -arch arm64 -sdk iphoneos -derivedDataPath $(POGOTMP) \
		CODE_SIGNING_ALLOWED=NO DSTROOT=$(POGOTMP)/install ALWAYS_EMBED_SWIFT_STANDARD_LIBRARIES=NO
	@rm -rf Payload
	@rm -rf $(POGO_STAGE_DIR)/
	@mkdir -p $(POGO_STAGE_DIR)/Payload
	@mv $(POGO_APP_DIR) $(POGO_STAGE_DIR)/Payload/Pogo.app

	@echo $(POGOTMP)
	@echo $(POGO_STAGE_DIR)

	@mv $(POGO_HELPER_PATH) $(POGO_STAGE_DIR)/Payload/Pogo.app//PogoHelper
	@$(TARGET_CODESIGN) -Sentitlements.xml $(POGO_STAGE_DIR)/Payload/Pogo.app/
	@$(TARGET_CODESIGN) -Sentitlements.xml $(POGO_STAGE_DIR)/Payload/Pogo.app//PogoHelper
	
	@rm -rf $(POGO_STAGE_DIR)/Payload/Pogo.app/_CodeSignature

	@ln -sf $(POGO_STAGE_DIR)/Payload Payload

	@rm -rf packages
	@mkdir -p packages

	@zip -r9 packages/Pogo.ipa Payload