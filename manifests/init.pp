# Class: play
#
# This module manages play framework applications and modules.
# The class itself installs Play 2.3.0 in /usr/share/play-2.3.0
#
# Actions:
#  play::module checks the availability of a Play module. It installs
#  it if not found
#  play::application starts a play application
#  play::service starts a play application as a system service
#
# Parameters:
# *version* : the Play version to install
#
# Requires:
# wget puppet module https://github.com/maestrodev/puppet-wget
# A proper java installation and JAVA_HOME set
# Sample Usage:
#  class {'play': 
#    version => "2.3.0",
#    user    => "play"
#  }
#  play::module {"mongodb module" :
#   module  => "mongo-1.3", 
# require => [Class["play"], Class["mongodb"]]
#  }
#
#  play::module { "less module" :
#   module  => "less-0.3",
# require => Class["play"]
#  }
#
#  play::service { "play" :
# path    => "/home/clement/demo/myapp",
# require => [Jdk6["Java6SDK"], Play::Module["mongodb module"]]
#  }
#
class play (
  $version, 
  $install_path = "/usr/share", 
  $user= "root") {

include wget

$play_path = "${install_path}/activator-${version}"
$download_url = "http://downloads.typesafe.com/typesafe-activator/${version}/typesafe-activator-${version}-minimal.zip"

notice("Installing Play Activator ${version}")
wget::fetch {'download-play-activator-framework':
  source      => "$download_url",
  destination => "/tmp/activator-${version}.zip",
  timeout     => 0,
}

exec { "mkdir.play.install.path":
  command => "/bin/mkdir -p ${install_path}",
  unless  => "/bin/bash [ -d ${install_path} ]"
}

exec {"unzip-play-framework":
  cwd     => "${install_path}",
  command => "/usr/bin/unzip /tmp/activator-${version}.zip",
  unless  => "/usr/bin/test -d $play_path",
  require => [ Package["unzip"], Wget::Fetch["download-play-activator-framework"], Exec["mkdir.play.install.path"] ],
}

exec { "change ownership of play installation":
  cwd      => "${install_path}",
  command  => "/bin/chown -R ${user}: activator-${version}",
  require  => Exec["unzip-play-framework"]

}

file { "$play_path/activator":
  ensure  => file,
  owner   => $user,
  mode    => "0755",
  require => [Exec["unzip-play-framework"]]
}

file {'/usr/bin/activator':
  ensure  => 'link',
  target  => "$play_path/activator",
  require => File["$play_path/activator"],
}

# Add a unversioned symlink to the play installation.
file { "${install_path}/activator":
  ensure => link,
  target => $play_path,
  require => Exec["mkdir.play.install.path", "unzip-play-framework"]
}

if !defined(Package['unzip']){ package{"unzip": ensure => installed} }
}
