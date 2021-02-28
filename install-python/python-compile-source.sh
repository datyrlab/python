#! /bin/bash

######################################
# Python Install - compile from source with SSL module, pip TLS/ SSL
# https://youtu.be/B8ImmR2GfYQ

# 0:00 - here, I'll first demonstrate a pip warning when Python is configured without the SSL module

# 1. if you are installing Python from scratch
# then follow this step by step guide
# ------------------------------
# 4:15 - install dependent libraries with sudo apt
# 11:05 - download the Python source file and unpack to a directory
# 17:22 - check any Python versions that are currently installed
# 20:32 - update the file 'setup.dist' located in the directory 'modules' with the path to openssl
# 28:56 - run configure with SSL enabled to create a Makefile
# 33:17 - run make to compile Python
# 39:43 - test your different Python versions and validate the SSL module is working for pip

# 2. if you are installing Python from scratch
# and prefer to run an automated script then I'll walk you a script that I've written
# Note: I've split the script into functions and show how to run each function or all in one pass
# ------------------------------
# 50:37 - run script

# 3. if you have already compiled Python and you would like to fix the SSL warning
# then go directly to this chapter and I'll show you how
# ------------------------------
# 20:32 - first make the necessary changes to your setup.dist file shown in previous chapter
# 1:06:44 - recompile Python with SSL enabled

# in my first Python install video I'd shown how to switch between Python versions using 'update-alternatives'
# https://youtu.be/uwoAr9R9POw?t=988

# https://twitter.com/datyrlab
######################################


# variables
#####################################
version="3.7.5"  
#https://www.python.org/ftp/python/
source_url="https://www.python.org/ftp/python/${version}/Python-${version}.tgz"
source_dir="/usr/local/python-source" 
openssl_dir="/usr"  

#LD_LIBRARY_PATH="/usr/local/lib"
#export LD_LIBRARY_PATH


package_list=(
    
    #autoconf               # Autoconf is an extensible package of M4 macros that produce shell scripts to automatically configure software source code packages. These scripts can adapt the packages to many kinds of UNIX-like systems without manual user intervention. Autoconf creates a configuration script for a package from a template file that lists the operating system features that the package can use, in the form of M4 macro calls
    #automake               # GNU Automake is a tool for automatically generating Makefile.in files compliant with the GNU Coding Standards. Automake requires the use of GNU Autoconf
    build-essential		    # c/c++ compiler
    checkinstall			# checkinstall keeps track of all the files created or modified by your installation script, builds a standard binary package (.deb, .rpm, .tgz) and installs it in your system giving you the ability to uninstall it with your distribution's standard package management utilities.)
    zlib1g-dev				# zlib is a library implementing the deflate compression method found in gzip and PKZIP. This package includes the development support files
    libncurses5-dev 	    # The ncurses library routines are a terminal-independent method of updating character screens with reasonable optimization.
    libgdbm-dev				# GNU dbm ('gdbm') is a library of database functions that use extendible hashing and works similarly to the standard UNIX 'dbm' functions. This package includes development support files
    libnss3-dev 			# This is a set of libraries designed to support cross-platform development of security-enabled client and server applications. It can support SSLv2 and v4, TLS, PKCS #5, #7, #11, #12, S/MIME, X.509 v3 certificates and other security standards
    libssl-dev				# This package is part of the OpenSSL projects implementation of the SSL and TLS cryptographic protocols for secure communication over the Internet.
    libreadline-dev			# The GNU readline library aids in the consistency of user interface across discrete programs that need to provide a command line interface.
    libffi-dev				# This package contains the headers and static library files necessary for building programs which use libffi.
    libsqlite3-dev			# SQLite is a C library that implements an SQL database engine. Programs that link with the SQLite library can have SQL database access without running a separate RDBMS process.
    libbz2-dev				# Static libraries and include files for the bzip2 compressor library.
    
)

# functions
#####################################
function package_install(){
    
    if  [[ $1 ]]; then eval "declare -A PACKAGE_LIST="${1#*=}; fi

    echo -e "\nDEPENDENCIES"
    echo -e "-----------------------------------------"
    
    for package in "${PACKAGE_LIST[@]}"; do 
        if [[ $package != "" ]]; then
        
            verify=$(dpkg -s $package)
            if [[ ${verify} =~ (Status: install ok) ]]; then
                echo -e "${package} is installed"

            else
                sudo apt install ${package} -y

            fi

            unset package
            unset verify

        fi

    done
}

function python_version() {

    if  [[ $1 ]]; then VERSION=$1; fi    

    #echo -e "\nchecking python installation"
    #echo -e "-----------------------------------------"
    
    # first digit, example: 3
    # for 'python3' or future 'python4'
    # will give you the current version of python that is set
    v=$(echo $VERSION | sed -r 's/^[^0-9]*([0-9]+).*$/\1/')
    
    # first 2 digits, example: 3.7
    # to check for a specific version of python or pip - might not be the same current version that is set
    # like the version you have just compiled but not yet set
    # to avoid bash errors we'll run the version check after we have compiled
    vv=$(echo $VERSION | sed -r 's/^[^0-9]*([0-9].[0-9]).*$/\1/')
    #last 3 digits not using this
    #vvv=$(echo $current_version | sed -nre 's/^[^0-9]*(([0-9]+\.)*[0-9]+).*/\1/p')
    
    # full string of version check
    # safe to run this now without bash errors since Debian/ Ubuntu comes pre-installed with python
    current_python_version=$(python${v} -V)
    current_pip_version=$(pip${v} -V)
    
    # installed versions
    # return a list of all installed versions of python
    all_python_versions=$(ls /usr/local/lib | grep python)
    all_pip_versions=$(whereis pip${v})
    
}

function python_source_download (){
    
    # list of releases
    
    if  [[ $1 ]]; then VERSION=$1; fi    
    if  [[ $2 ]]; then SOURCE_URL=$2; fi    
    if  [[ $3 ]]; then SOURCE_DIR=$3; fi    

    echo -e "\nDOWNLOAD SOURCE"
    echo -e "-----------------------------------------"
    python_version ${VERSION}
    # before starting install, print to the terminal what current versions are installed 
    if [[ $current_python_version ]]; then echo -e "current python version is set to: ${current_python_version}"; fi
    if [[ $current_pip_version ]]; then echo -e "current pip3 version is set to: ${current_pip_version}"; fi
    if [[ $all_python_versions ]]; then echo -e "all python versions installed:" ${all_python_versions}; fi
    if [[ $all_pip_versions ]]; then echo -e "all pip3 versions installed:" ${all_pip_versions}; fi
    
    if [[ "${current_python_version}" != "${VERSION}" ]]; then
        
        source_file=$(echo ${SOURCE_URL##*/})

        if [ ! -d ${SOURCE_DIR} ]; then
            sudo mkdir ${SOURCE_DIR}
        fi
        
        if [ ! -f "/tmp/${source_file}" ]; then
            wget -P /tmp "${SOURCE_URL}"
        fi
        
        unpacked_dir="${source_file%.*}" 
        target_dir="${SOURCE_DIR}/${unpacked_dir}"
        if [ -d ${SOURCE_DIR} ] && [ ! -d "${target_dir}" ]; then
            sudo tar -xzvf "/tmp/${source_file}" -C "${SOURCE_DIR}"

        fi
        
        if [ -d "${target_dir}" ]; then
            echo -e "source location: ${target_dir}"
        fi

    else 
        echo -e "already installed: ${VERSION}" 

    fi

}

function python_openssl() {

    if  [[ $1 ]]; then OPENSSL_DIR=$1; fi    
    if  [[ $2 ]] && [ $2 != "" ]; then TARGET_DIR=$2; fi    
    
    echo -e "\nPYTHON OPENSSL (modify file setup file)"
    echo -e "-----------------------------------------"
    
    # adding a commented marker upon changing the file makes it easier to look for an ID informing it was already changed
    mymarker="#enabled-my-custom-ssl-${OPENSSL_DIR}"
    
    # 'Setup.dist' creates Setup
    sf=(
        "${target_dir}/Modules/Setup.dist"
        #"${target_dir}/Modules/Setup"
    )
    
    for setup_file in "${sf[@]}"; do 
        if [ -f "${setup_file}" ]; then
            if grep -Fxq "$mymarker" "${setup_file}"; then
                echo -e "file already configured: ${setup_file}"
                
            else
                myopenssl_dir=${OPENSSL_DIR}
                sudo sed -i 's@#_socket socketmodule.c@_socket socketmodule.c@g' ${setup_file}              
                sudo sed -i "s@#SSL=/usr/local/ssl@${mymarker}\nSSL=${myopenssl_dir}@g" ${setup_file}              
                sudo sed -i 's@#_ssl _ssl.c \\@_ssl _ssl.c \\@g' ${setup_file}              
                sudo sed -i 's@#\t-DUSE_SSL -I$(SSL)/include -I$(SSL)/include/openssl \\@\t-DUSE_SSL -I$(SSL)/include -I$(SSL)/include/openssl \\@g' ${setup_file}              
                sudo sed -i 's@#\t-L$(SSL)/lib -lssl -lcrypto@\t-L$(SSL)/lib -lssl -lcrypto@g' ${setup_file}              

                echo -e "updated: ${setup_file}"
                
            fi
        
        fi
    done

}

function python_configure() {

    if  [[ $1 ]]; then VERSION=$1; fi    
    if  [[ $2 ]] && [ $2 != "" ]; then TARGET_DIR=$2; fi    
    if  [[ $3 ]]; then OPENSSL_DIR=$3; fi    
    
    echo -e "\nPYTHON CONFIGURE (Makefile)"
    echo -e "-----------------------------------------"
    python_version ${VERSION}
    
    if [ ! -f "${TARGET_DIR}/Makefile" ]; then
        cd ${TARGET_DIR}
        
        if [[ $OPENSSL_DIR ]]; then
            # with explicit path to your installation of ssl
            python_openssl "${OPENSSL_DIR}" "${TARGET_DIR}" # and modification of /Modules/Setup.dist
            sudo ./configure --enable-optimizations --with-openssl="${OPENSSL_DIR}"
        
        else
            sudo ./configure --enable-optimizations 

        fi

    else
        echo -e "openssl directory: ${OPENSSL_DIR}"
        echo -e "already exists: ${TARGET_DIR}/Makefile"

    fi
    
}

function python_build() {

    if  [[ $1 ]]; then VERSION=$1; fi    
    if  [[ $2 ]] && [ $2 != "" ]; then TARGET_DIR=$2; fi    
    
    echo -e "\nPYTHON BUILD (install)"
    echo -e "-----------------------------------------"
    python_version ${VERSION}
   
    get_ver="python${vv} -V"
    if output=$($get_ver); then
        echo -e "already installed: ${VERSION}"
        whereis python${VERSION} 
    else
        if [ -f "${TARGET_DIR}/Makefile" ]; then
            cd ${TARGET_DIR}
            
            cores=$(grep -c ^processor /proc/cpuinfo)
            sudo make -j $cores altinstall 

        fi
    
    fi
    
}

#####################################

package_install "$(declare -p package_list)"
python_source_download "${version}" "${source_url}" "${source_dir}"
#python_configure "${version}" "${target_dir}"                      # without explicit ssl
python_configure "${version}" "${target_dir}" "${openssl_dir}"      # with explicit ssl
python_build "${version}" "${target_dir}"





