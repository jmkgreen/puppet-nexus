# Resource: cescoffier_nexus::artifact
#
# This resource downloads Maven Artifacts from Nexus
#
# Parameters:
# [*gav*] : The artifact groupid:artifactid:version (mandatory)
# [*packaging*] : The packaging type (jar by default)
# [*classifier*] : The classifier (no classifier by default)
# [*repository*] : The repository such as 'public', 'central'...(mandatory)
# [*output*] : The output file (mandatory)
# [*ensure*] : If 'absent' deletes the output file, otherwise ensure latest version of the artifact based on modified time.
# [*timeout*] : Optional timeout for download exec. 0 disables - see exec for default.
# [*owner*] : Optional user to own the file
# [*group*] : Optional group to own the file
# [*mode*] : Optional mode for file
#
# Actions:
# If ensure is set to 'absent' we delete the output file.
# If ensure is not set or set to anything other than 'absent', the artifact is re-downloaded if the remote file is newer or the local file does not yet exist.
#
# Sample Usage:
#  class cescoffier_nexus {
#   url => http://edge.spree.de/nexus,
#   username => user,
#   password => password
# }
#
define cescoffier_nexus::artifact(
	$gav,
	$packaging = "jar",
	$classifier = "",
	$repository,
	$output,
	$ensure = undef,
	$timeout = undef,
	$owner = undef,
	$group = undef,
	$mode = undef
	) {
	
	include cescoffier_nexus
	
	if ($cescoffier_nexus::authentication) {
		$args = "-u ${cescoffier_nexus::user} -p '${cescoffier_nexus::pwd}'"
	} else {
		$args = ""
	}

	if ($classifier) {
		$includeClass = "-c ${classifier}"	
	}

	$cmd = "/opt/nexus-script/download-artifact-from-nexus.sh -a ${gav} -e ${packaging} ${$includeClass} -n ${cescoffier_nexus::NEXUS_URL} -r ${repository} -o ${output} $args -v"

	if $ensure != absent {
		exec { "Checking ${gav}-${classifier}":
			command => "${cmd} -z",
			timeout => $timeout,
			before => Exec["Download ${gav}-${classifier}"] 
		}
		exec { "Download ${gav}-${classifier}":
			command => $cmd,
			creates  => "${output}",
			timeout => $timeout
		}
	} else {
		file { "Remove ${gav}-${classifier}":
			path   => $output,
			ensure => absent
		}
	}

    if $ensure != absent {
      file { "${output}":
        ensure => file,
        require => Exec["Download ${gav}-${classifier}"],
        owner => $owner,
        group => $group,
        mode => $mode
      }
    }

}
