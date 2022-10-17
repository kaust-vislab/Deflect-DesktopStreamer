# Copyright (c) 2012-2017 Stefan Eilemann <eile@eyescale.ch>

# Configures a Doxyfile and provides doxygen and doxycopy targets. Relies on
# TargetHooks installed by Common and must be included after all targets!
#
# Input Variables
# * DOXYGEN_EXTRA_EXCLUDE additional excluded input files, appended to EXCLUDE
#   in Doxyfile
# * DOXYGEN_EXTRA_FILES additional files to be copied to documentation,
#   appended to HTML_EXTRA_FILES in Doxyfile
# * DOXYGEN_EXTRA_INPUT additional parsed input files, appended to INPUT in
#   Doxyfile
# * DOXYGEN_EXTRA_STYLESHEET additional css style sheet to assign to the
#   HTML_EXTRA_STYLESHEET variable in Doxyfile
# * DOXYGEN_MAINPAGE_MD markdown file to use as main page. See
#   USE_MDFILE_AS_MAINPAGE doxygen documentation for details.
# * DOXYGEN_PREDEFINED_MACROS additional input to the PREDEFINED variable in
#   Doxyfile.
# * DOXYGEN_PROJECT_BRIEF A short description of the project. Defaults to
#   ${UPPER_PROJECT_NAME}_DESCRIPTION if not provided.
# * DOXYGEN_PROJECT_LOGO the logo to use next to the documentation title.
# * DOXYGEN_PROJECT_NAME the name to use in the documentation title. Defaults
#   to PROJECT_NAME if not provided.
# * DOXYGEN_PROJECT_VERSION The full version of the project. Defaults to
#   ${PROJECT_NAME}_VERSION if not provided.
# * ${PROJECT_NAME}_VERSION_(MINOR|MAJOR) The project's major/minor version,
#   generally set by the project() command in the top-level CMakeLists.txt.
#
# Input Global Properties
# * ${PROJECT_NAME}_HELP a list of doxygen page anchors to add to the
#   "Application Help" page
#
# Optional project information
# Output to a metadata file for html index page generation by Jekyll
# * ${UPPER_PROJECT_NAME}_DESCRIPTION A short description of the project
# * ${UPPER_PROJECT_NAME}_ISSUES_URL A link pointing to the ticket tracker
# * ${UPPER_PROJECT_NAME}_PACKAGE_URL A link pointing to the package repository
# * ${UPPER_PROJECT_NAME}_MATURITY EP, RD or RS
# * ${UPPER_PROJECT_NAME}_URL A link pointing to the package homepage
#
# IO Variables (set if not set as input)
# * GIT_DOCUMENTATION_REPO or GIT_ORIGIN_ORG (from GithubInfo.cmake) is used
# * DOXYGEN_CONFIG_FILE or one is auto-configured
# * COMMON_ORGANIZATION_NAME (from GithubInfo. Defaults to: Unknown)
# * COMMON_PROJECT_DOMAIN a reverse DNS name. (Defaults to: org.doxygen)
#
# Generated targets
# * (PROJECT-)doxygen generates documentation on installed headers
# * (PROJECT-)doxycopy runs doxygen and then copies the documentation to the
#   documention folder, which is assumed to be located at:
#   PROJECT_SOURCE_DIR/../GIT_DOCUMENTATION_REPO or
#   PROJECT_SOURCE_DIR/../GIT_ORIGIN_org
#   When using subprojects, it is the responsibility of the user to clone
#   the documentation repository in the project's parent folder.

if(NOT DOXYGEN_FOUND)
  find_package(Doxygen QUIET)
endif()
if(NOT DOXYGEN_FOUND)
  return()
endif()

if(NOT TARGET ${PROJECT_NAME}-all)
  message(FATAL_ERROR "No ${PROJECT_NAME}-all target, Common.cmake not used?")
endif()

include(CommonDate)

if(NOT GIT_DOCUMENTATION_REPO)
  include(GithubInfo)
  set(GIT_DOCUMENTATION_REPO ${GIT_ORIGIN_ORG})
endif()

if(NOT PROJECT_PACKAGE_NAME)
  if(NOT COMMON_PROJECT_DOMAIN)
    set(COMMON_PROJECT_DOMAIN org.doxygen)
    message(STATUS "Set COMMON_PROJECT_DOMAIN to ${COMMON_PROJECT_DOMAIN}")
  endif()
  set(PROJECT_PACKAGE_NAME ${COMMON_PROJECT_DOMAIN}.${LOWER_PROJECT_NAME})
endif()

if(NOT DOXYGEN_PROJECT_NAME)
  set(DOXYGEN_PROJECT_NAME ${PROJECT_NAME})
endif()

if(NOT DOXYGEN_PROJECT_VERSION)
  set(DOXYGEN_PROJECT_VERSION ${${PROJECT_NAME}_VERSION})
endif()

if(NOT DOXYGEN_PROJECT_BRIEF)
  set(DOXYGEN_PROJECT_BRIEF ${${UPPER_PROJECT_NAME}_DESCRIPTION})
endif()

if(NOT COMMON_ORGANIZATION_NAME)
  set(COMMON_ORGANIZATION_NAME Unknown)
endif()

# collect application help page
get_property(__help GLOBAL PROPERTY ${PROJECT_NAME}_HELP)
if(__help)
  list(APPEND DOXYGEN_EXTRA_INPUT ${PROJECT_BINARY_DIR}/help)
  set(__index "${PROJECT_BINARY_DIR}/help/applications.md")
  file(WRITE ${__index} "Application Help {#apps}
============

")
  foreach(_help ${__help})
    file(APPEND ${__index} "* @subpage ${_help}\n")
  endforeach()
endif()

# list-to-string transform
string(REPLACE ";" " " DOXYGEN_EXTRA_INPUT "${DOXYGEN_EXTRA_INPUT}")

if(NOT DOXYGEN_CONFIG_FILE)
  # Assuming there exists a Doxyfile and that needs configuring
  configure_file(${CMAKE_CURRENT_LIST_DIR}/Doxyfile
    ${PROJECT_BINARY_DIR}/doc/Doxyfile @ONLY)
  set(DOXYGEN_CONFIG_FILE ${PROJECT_BINARY_DIR}/doc/Doxyfile)
endif()

add_custom_target(${PROJECT_NAME}-doxygen
  ${DOXYGEN_EXECUTABLE} ${DOXYGEN_CONFIG_FILE}
  WORKING_DIRECTORY ${PROJECT_BINARY_DIR}/doc
  COMMENT "Generating ${PROJECT_NAME} API documentation using doxygen" VERBATIM
  DEPENDS ${PROJECT_NAME}-install project_info_${PROJECT_NAME})
set_target_properties(${PROJECT_NAME}-doxygen PROPERTIES
  EXCLUDE_FROM_DEFAULT_BUILD ON FOLDER ${PROJECT_NAME}/doxygen)
if(TARGET ${PROJECT_NAME}-coverage) # CoverageReport generated by "tests" in this case
  add_dependencies(${PROJECT_NAME}-doxygen ${PROJECT_NAME}-coverage)
endif()
if(TARGET ${PROJECT_NAME}-help)
  add_dependencies(${PROJECT_NAME}-doxygen ${PROJECT_NAME}-help)
endif()

if(NOT TARGET doxygen)
  add_custom_target(doxygen)
  set_target_properties(doxygen PROPERTIES EXCLUDE_FROM_DEFAULT_BUILD ON)
endif()
add_dependencies(doxygen ${PROJECT_NAME}-doxygen)

make_directory(${PROJECT_BINARY_DIR}/doc/html)
install(DIRECTORY ${PROJECT_BINARY_DIR}/doc/html
  DESTINATION ${COMMON_DOC_DIR}/API
  COMPONENT doc CONFIGURATIONS Release)

set(README)
set(README_TYPE text/plain)
if(EXISTS ${PROJECT_SOURCE_DIR}/README.md)
  file(READ ${PROJECT_SOURCE_DIR}/README.md README)
  set(README_TYPE text/x-markdown)
elseif(EXISTS ${PROJECT_SOURCE_DIR}/README.txt)
  file(READ ${PROJECT_SOURCE_DIR}/README.txt README)
elseif(EXISTS ${PROJECT_SOURCE_DIR}/README)
  file(READ ${PROJECT_SOURCE_DIR}/README README)
endif()

string(REPLACE ";" "; " AUTHORS "${GIT_AUTHORS}")
string(REPLACE "<" "(" MAINTAINER "${${UPPER_PROJECT_NAME}_MAINTAINER}")
string(REPLACE ">" ")" MAINTAINER "${MAINTAINER}")

# Write the project's metadata file (for Jekyll index page and other consumers)
set(_version_major ${${PROJECT_NAME}_VERSION_MAJOR})
set(_version_minor ${${PROJECT_NAME}_VERSION_MINOR})
set(_version "${_version_major}.${_version_minor}")

set(_jekyll_md_file "${PROJECT_BINARY_DIR}/doc/${PROJECT_NAME}-${_version}.md")
file(WRITE ${_jekyll_md_file}
"---\n"
"name: ${PROJECT_NAME}\n"
"version: \"${_version}\"\n"
"major: ${_version_major}\n"
"minor: ${_version_minor}\n"
"description: ${DOXYGEN_PROJECT_BRIEF}\n"
"updated: ${COMMON_DATE}\n"
"homepage: ${${UPPER_PROJECT_NAME}_URL}\n"
"repository: ${GIT_ORIGIN_URL}\n"
"issuesurl: ${${UPPER_PROJECT_NAME}_ISSUES_URL}\n"
"packageurl: ${${UPPER_PROJECT_NAME}_PACKAGE_URL}\n"
"license: ${${UPPER_PROJECT_NAME}_LICENSE}\n"
"maturity: ${${UPPER_PROJECT_NAME}_MATURITY}\n"
"maintainers: ${MAINTAINER}\n"
"contributors: ${AUTHORS}\n"
"readmetype: ${README_TYPE}\n"
"---\n"
"${README}\n")

# Create 'doxycopy' target
if(GIT_DOCUMENTATION_REPO)
  set(_git_doc_repo_dir "${PROJECT_SOURCE_DIR}/../${GIT_DOCUMENTATION_REPO}")

  if(IS_DIRECTORY ${_git_doc_repo_dir})
    set(_doc_destination_dir ${_git_doc_repo_dir}/${PROJECT_NAME}-${_version})
    add_custom_target(${PROJECT_NAME}-doxycopy
      COMMAND ${CMAKE_COMMAND} -E remove_directory ${_doc_destination_dir}
      COMMAND ${CMAKE_COMMAND} -E remove -f ${CMAKE_BINARY_DIR}/${GIT_DOCUMENTATION_REPO}/doxygit-generated
      COMMAND ${CMAKE_COMMAND} -E copy_directory ${PROJECT_BINARY_DIR}/doc/html ${_doc_destination_dir}
      COMMAND ${CMAKE_COMMAND} -E copy ${_jekyll_md_file} ${_git_doc_repo_dir}/_projects
      COMMENT "Copying ${PROJECT_NAME} API documentation to ${_doc_destination_dir}"
      DEPENDS ${PROJECT_NAME}-doxygen VERBATIM)
  else()
    # Having a command will force this target to run always when invoked. That
    # makes the Makefile to print the comment. The text will be also visible
    # in ninja.
    add_custom_target(${PROJECT_NAME}-doxycopy
      COMMAND ${CMAKE_COMMAND} -E echo ""
      COMMENT "doxycopy target not available, missing ${_git_doc_repo_dir}")
  endif()
else()
  add_custom_target(${PROJECT_NAME}-doxycopy
    # Same as above
    COMMAND ${CMAKE_COMMAND} -E echo ""
    COMMENT "doxycopy target not available, missing GIT_DOCUMENTATION_REPO")
endif()
set_target_properties(${PROJECT_NAME}-doxycopy PROPERTIES
  EXCLUDE_FROM_DEFAULT_BUILD ON FOLDER ${PROJECT_NAME}/doxygen)

if(NOT TARGET doxycopy)
  add_custom_target(doxycopy)
  set_target_properties(doxycopy PROPERTIES EXCLUDE_FROM_DEFAULT_BUILD ON)
endif()
add_dependencies(doxycopy ${PROJECT_NAME}-doxycopy)
