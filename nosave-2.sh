#
# Copyright (C) 2016  Red Hat, Inc.
#
# This copyrighted material is made available to anyone wishing to use,
# modify, copy, or redistribute it subject to the terms and conditions of
# the GNU General Public License v.2, or (at your option) any later version.
# This program is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY expressed or implied, including the implied warranties of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
# Public License for more details.  You should have received a copy of the
# GNU General Public License along with this program; if not, write to the
# Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA
# 02110-1301, USA.  Any Red Hat trademarks that are incorporated in the
# source code or documentation are not subject to the GNU General Public
# License and may only be used or replicated with the express permission of
# Red Hat, Inc.
#
# Red Hat Author(s): Vendula Poncova <vponcova@redhat.com>

TESTTYPE="logs"

. ${KSTESTDIR}/functions.sh

kernel_args() {
    echo ${DEFAULT_BOOTOPTS} inst.nosave=output_ks
}

validate_logs() {
    # Does the file exists?
    existence=$(guestfish --ro $1 -i exists $2)
    # Check the result.
    if [[ "${existence}" != "${3}" ]]; then
        status=1
        echo "*** The existence of ${2} is not ${3}."
    fi
}

validate() {
    disksdir=$1
    args=$(for d in ${disksdir}/disk-*img; do echo -a ${d}; done)

    # Grab files out of the installed system while it still exists.
    # Grab these files:
    #
    # logs from Anaconda - whole /var/log/anaconda/ directory is copied out,
    #                      this can be used for saving specific test output
    # anaconda.coverage
    # RESULT file from the test
    for item in /root/anaconda.coverage \
                /var/log/anaconda/      \
                /root/RESULT
    do
        run_with_timeout 1000s "virt-copy-out ${args} ${item} ${disksdir}" 2>/dev/null
    done

    # The /root/RESULT file was saved from the VM.  Check its contents
    # and decide whether the test finally succeeded or not.
    result=$(cat ${disksdir}/RESULT)
    if [[ $? != 0 ]]; then
        status=1
        echo '*** /root/RESULT does not exist in VM image.'
    elif [[ "${result}" != SUCCESS* ]]; then
        status=1
        echo "${result}"
    else
        # Check the existence of the ks files and logs.
        validate_logs "${args}" /root/original-ks.cfg true  #input_ks
        validate_logs "${args}" /root/anaconda-ks.cfg false #output_ks
        validate_logs "${args}" /var/log/anaconda/    true  #logs
    fi

    return ${status}
}
