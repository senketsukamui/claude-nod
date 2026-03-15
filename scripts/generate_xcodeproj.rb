#!/usr/bin/env ruby

require "fileutils"
require "pathname"
require "xcodeproj"

ROOT = File.expand_path("..", __dir__)
PROJECT_PATH = File.join(ROOT, "ClaudeNod.xcodeproj")
SOURCES_DIR = File.join(ROOT, "Sources")
CONFIG_DIR = File.join(ROOT, "Config")

FileUtils.rm_rf(PROJECT_PATH)

project = Xcodeproj::Project.new(PROJECT_PATH)
project.root_object.attributes["LastSwiftUpdateCheck"] = "1600"
project.root_object.attributes["LastUpgradeCheck"] = "1600"

main_group = project.main_group
sources_group = main_group.new_group("Sources", "Sources")
config_group = main_group.new_group("Config", "Config")

source_files = Dir.glob(File.join(SOURCES_DIR, "*.swift")).sort
source_refs = source_files.map do |path|
  sources_group.new_file(File.basename(path))
end

config_group.new_file("ClaudeNod-Info.plist")

target = project.new_target(:application, "ClaudeNod", :osx, "14.0")
target.product_name = "ClaudeNod"
target.product_reference.name = "ClaudeNod.app"
target.add_file_references(source_refs)

target.build_configurations.each do |config|
  config.build_settings["PRODUCT_BUNDLE_IDENTIFIER"] = "com.senketsukamui.claudenod"
  config.build_settings["PRODUCT_NAME"] = "$(TARGET_NAME)"
  config.build_settings["SWIFT_VERSION"] = "6.0"
  config.build_settings["GENERATE_INFOPLIST_FILE"] = "NO"
  config.build_settings["INFOPLIST_FILE"] = "Config/ClaudeNod-Info.plist"
  config.build_settings["CODE_SIGN_STYLE"] = "Automatic"
  config.build_settings["DEVELOPMENT_TEAM"] = ""
  config.build_settings["MACOSX_DEPLOYMENT_TARGET"] = "14.0"
  config.build_settings["SDKROOT"] = "macosx"
  config.build_settings["ENABLE_APP_SANDBOX"] = "NO"
  config.build_settings["ASSETCATALOG_COMPILER_APPICON_NAME"] = ""
  config.build_settings["CURRENT_PROJECT_VERSION"] = "1"
  config.build_settings["MARKETING_VERSION"] = "0.1.0"
end

project.build_configurations.each do |config|
  config.build_settings["MACOSX_DEPLOYMENT_TARGET"] = "14.0"
end

project.save
