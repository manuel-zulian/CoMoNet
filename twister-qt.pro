TEMPLATE = app
TARGET = twisterd
macx:TARGET = "Twisterd"
VERSION = 0.8.2
INCLUDEPATH += src src/json src/qt
QT += core gui network widgets
greaterThan(QT_MAJOR_VERSION, 4): QT += widgets
DEFINES += BOOST_THREAD_USE_LIB BOOST_SPIRIT_THREADSAFE
CONFIG += no_include_pwd
CONFIG += thread

# for boost 1.37, add -mt to the boost libraries
# use: qmake BOOST_LIB_SUFFIX=-mt
# for boost thread win32 with _win32 sufix
# use: BOOST_THREAD_LIB_SUFFIX=_win32-...
# or when linking against a specific BerkelyDB version: BDB_LIB_SUFFIX=-4.8

# Dependency library locations can be customized with:
#    BOOST_INCLUDE_PATH, BOOST_LIB_PATH, BDB_INCLUDE_PATH,
#    BDB_LIB_PATH, OPENSSL_INCLUDE_PATH and OPENSSL_LIB_PATH respectively

OBJECTS_DIR = build
MOC_DIR = build
UI_DIR = build

# use: qmake "RELEASE=1"
contains(RELEASE, 1) {
    # Mac: compile for maximum compatibility (10.5, 32-bit)
    macx:QMAKE_CXXFLAGS += -mmacosx-version-min=10.5 -arch i386 -isysroot /Developer/SDKs/MacOSX10.5.sdk
    macx:QMAKE_CFLAGS += -mmacosx-version-min=10.5 -arch i386 -isysroot /Developer/SDKs/MacOSX10.5.sdk
    macx:QMAKE_OBJECTIVE_CFLAGS += -mmacosx-version-min=10.5 -arch i386 -isysroot /Developer/SDKs/MacOSX10.5.sdk

    !win32:!macx {
        # Linux: static link and extra security (see: https://wiki.debian.org/Hardening)
        LIBS += -Wl,-Bstatic -Wl,-z,relro -Wl,-z,now
    }
}

!win32 {
    # for extra security against potential buffer overflows: enable GCCs Stack Smashing Protection
    QMAKE_CXXFLAGS *= -fstack-protector-all
    QMAKE_LFLAGS *= -fstack-protector-all
    # Exclude on Windows cross compile with MinGW 4.2.x, as it will result in a non-working executable!
    # This can be enabled for Windows, when we switch to MinGW >= 4.4.x.
}
# for extra security (see: https://wiki.debian.org/Hardening): this flag is GCC compiler-specific
QMAKE_CXXFLAGS *= -D_FORTIFY_SOURCE=2
# for extra security on Windows: enable ASLR and DEP via GCC linker flags
win32:QMAKE_LFLAGS *= -Wl,--dynamicbase -Wl,--nxcompat
# on Windows: enable GCC large address aware linker flag
win32:QMAKE_LFLAGS *= -Wl,--large-address-aware

# use: qmake "USE_QRCODE=1"
# libqrencode (http://fukuchi.org/works/qrencode/index.en.html) must be installed for support
contains(USE_QRCODE, 1) {
    message(Building with QRCode support)
    DEFINES += USE_QRCODE
    LIBS += -lqrencode
}

# use: qmake "USE_DBUS=1"
contains(USE_DBUS, 1) {
    message(Building with DBUS (Freedesktop notifications) support)
    DEFINES += USE_DBUS
    QT += dbus
}

# use: qmake "USE_IPV6=1" ( enabled by default; default)
#  or: qmake "USE_IPV6=0" (disabled by default)
#  or: qmake "USE_IPV6=-" (not supported)
contains(USE_IPV6, -) {
    message(Building without IPv6 support)
} else {
    count(USE_IPV6, 0) {
        USE_IPV6=1
    }
    DEFINES += USE_IPV6=$$USE_IPV6
}

contains(BITCOIN_NEED_QT_PLUGINS, 1) {
    DEFINES += BITCOIN_NEED_QT_PLUGINS
    QTPLUGIN += qcncodecs qjpcodecs qtwcodecs qkrcodecs qtaccessiblewidgets
}

INCLUDEPATH += src/leveldb/include src/leveldb/helpers
LIBS += $$PWD/src/leveldb/libleveldb.a $$PWD/src/leveldb/libmemenv.a
!win32 {
    # we use QMAKE_CXXFLAGS_RELEASE even without RELEASE=1 because we use RELEASE to indicate linking preferences not -O preferences
    genleveldb.commands = cd $$PWD/src/leveldb && CC=$$QMAKE_CC CXX=$$QMAKE_CXX $(MAKE) OPT=\"$$QMAKE_CXXFLAGS $$QMAKE_CXXFLAGS_RELEASE\" libleveldb.a libmemenv.a
} else {
    # make an educated guess about what the ranlib command is called
    isEmpty(QMAKE_RANLIB) {
        QMAKE_RANLIB = $$replace(QMAKE_STRIP, strip, ranlib)
    }
    LIBS += -lshlwapi
    genleveldb.commands = cd $$PWD/src/leveldb && CC=$$QMAKE_CC CXX=$$QMAKE_CXX TARGET_OS=OS_WINDOWS_CROSSCOMPILE $(MAKE) OPT=\"$$QMAKE_CXXFLAGS $$QMAKE_CXXFLAGS_RELEASE\" libleveldb.a libmemenv.a && $$QMAKE_RANLIB $$PWD/src/leveldb/libleveldb.a && $$QMAKE_RANLIB $$PWD/src/leveldb/libmemenv.a
}
genleveldb.target = $$PWD/src/leveldb/libleveldb.a
genleveldb.depends = FORCE
PRE_TARGETDEPS += $$PWD/src/leveldb/libleveldb.a
QMAKE_EXTRA_TARGETS += genleveldb
# Gross ugly hack that depends on qmake internals, unfortunately there is no other way to do it.
QMAKE_CLEAN += $$PWD/src/leveldb/libleveldb.a; cd $$PWD/src/leveldb ; $(MAKE) clean

# libtorrent hack
INCLUDEPATH += libtorrent/include
LIBS += $$PWD/libtorrent/src/.libs/libtorrent-rasterbar.a
DEFINES += TORRENT_DEBUG
DEFINES += BOOST_ASIO_SEPARATE_COMPILATION
#DEFINES += BOOST_ASIO_DYN_LINK
!win32 {
    libtorrent.commands = cd $$PWD/libtorrent && CC=$$QMAKE_CC CXX=$$QMAKE_CXX $(MAKE) OPT=\"$$QMAKE_CXXFLAGS $$QMAKE_CXXFLAGS_RELEASE\"
}
libtorrent.target = $$PWD/libtorrent/src/.libs/libtorrent-rasterbar.a
libtorrent.depends = FORCE
PRE_TARGETDEPS += $$PWD/libtorrent/src/.libs/libtorrent-rasterbar.a
QMAKE_EXTRA_TARGETS += libtorrent
# Gross ugly hack that depends on qmake internals, unfortunately there is no other way to do it.
QMAKE_CLEAN += $$PWD/libtorrent/src/.libs/libtorrent-rasterbar.a; cd $$PWD/libtorrent ; $(MAKE) clean


# regenerate src/build.h
!win32|contains(USE_BUILD_INFO, 1) {
    genbuild.depends = FORCE
    genbuild.commands = cd $$PWD; /bin/sh share/genbuild.sh $$OUT_PWD/build/build.h
    genbuild.target = $$OUT_PWD/build/build.h
    PRE_TARGETDEPS += $$OUT_PWD/build/build.h
    QMAKE_EXTRA_TARGETS += genbuild
    DEFINES += HAVE_BUILD_INFO
}

QMAKE_CXXFLAGS_WARN_ON = -fdiagnostics-show-option -Wall -Wextra -Wformat -Wformat-security -Wno-unused-parameter -Wstack-protector

# Input
DEPENDPATH += src src/json src/qt
HEADERS +=  \
    src/alert.h \
    src/addrman.h \
    src/base58.h \
    src/bignum.h \
    src/chainparams.h \
    src/checkpoints.h \
    src/softcheckpoint.h \
    src/compat.h \
    src/sync.h \
    src/util.h \
    src/hash.h \
    src/uint256.h \
    src/serialize.h \
    src/core.h \
    src/main.h \
    src/net.h \
    src/key.h \
    src/db.h \
    src/walletdb.h \
    src/script.h \
    src/init.h \
    src/bloom.h \
    src/mruset.h \
    src/checkqueue.h \
    src/json/json_spirit_writer_template.h \
    src/json/json_spirit_writer.h \
    src/json/json_spirit_value.h \
    src/json/json_spirit_utils.h \
    src/json/json_spirit_stream_reader.h \
    src/json/json_spirit_reader_template.h \
    src/json/json_spirit_reader.h \
    src/json/json_spirit_error_position.h \
    src/json/json_spirit.h \
    src/wallet.h \
    src/keystore.h \
    src/bitcoinrpc.h \
    src/crypter.h \
    src/protocol.h \
    src/allocators.h \
    src/ui_interface.h \
    src/version.h \
    src/netbase.h \
    src/clientversion.h \
    src/txdb.h \
    src/leveldb.h \
    src/threadsafety.h \
    src/limitedmap.h \
    src/scrypt.h \
    src/utf8core.h \
    src/dhtproxy.h \
    src/twister.h \
    src/twister_rss.h \
    src/twister_utils.h \
    libtorrent/include/libtorrent/aux_/session_impl.hpp \
    libtorrent/include/libtorrent/extensions/logger.hpp \
    libtorrent/include/libtorrent/extensions/lt_trackers.hpp \
    libtorrent/include/libtorrent/extensions/metadata_transfer.hpp \
    libtorrent/include/libtorrent/extensions/smart_ban.hpp \
    libtorrent/include/libtorrent/extensions/ut_metadata.hpp \
    libtorrent/include/libtorrent/extensions/ut_pex.hpp \
    libtorrent/include/libtorrent/kademlia/dht_get.hpp \
    libtorrent/include/libtorrent/kademlia/dht_observer.hpp \
    libtorrent/include/libtorrent/kademlia/dht_tracker.hpp \
    libtorrent/include/libtorrent/kademlia/find_data.hpp \
    libtorrent/include/libtorrent/kademlia/logging.hpp \
    libtorrent/include/libtorrent/kademlia/msg.hpp \
    libtorrent/include/libtorrent/kademlia/node.hpp \
    libtorrent/include/libtorrent/kademlia/node_entry.hpp \
    libtorrent/include/libtorrent/kademlia/node_id.hpp \
    libtorrent/include/libtorrent/kademlia/observer.hpp \
    libtorrent/include/libtorrent/kademlia/refresh.hpp \
    libtorrent/include/libtorrent/kademlia/routing_table.hpp \
    libtorrent/include/libtorrent/kademlia/rpc_manager.hpp \
    libtorrent/include/libtorrent/kademlia/traversal_algorithm.hpp \
    libtorrent/include/libtorrent/add_torrent_params.hpp \
    libtorrent/include/libtorrent/address.hpp \
    libtorrent/include/libtorrent/alert.hpp \
    libtorrent/include/libtorrent/alert_dispatcher.hpp \
    libtorrent/include/libtorrent/alert_manager.hpp \
    libtorrent/include/libtorrent/alert_types.hpp \
    libtorrent/include/libtorrent/alloca.hpp \
    libtorrent/include/libtorrent/allocator.hpp \
    libtorrent/include/libtorrent/assert.hpp \
    libtorrent/include/libtorrent/bandwidth_limit.hpp \
    libtorrent/include/libtorrent/bandwidth_manager.hpp \
    libtorrent/include/libtorrent/bandwidth_queue_entry.hpp \
    libtorrent/include/libtorrent/bandwidth_socket.hpp \
    libtorrent/include/libtorrent/bencode.hpp \
    libtorrent/include/libtorrent/bitfield.hpp \
    libtorrent/include/libtorrent/bloom_filter.hpp \
    libtorrent/include/libtorrent/broadcast_socket.hpp \
    libtorrent/include/libtorrent/bt_peer_connection.hpp \
    libtorrent/include/libtorrent/buffer.hpp \
    libtorrent/include/libtorrent/build_config.hpp \
    libtorrent/include/libtorrent/chained_buffer.hpp \
    libtorrent/include/libtorrent/config.hpp \
    libtorrent/include/libtorrent/connection_queue.hpp \
    libtorrent/include/libtorrent/ConvertUTF.h \
    libtorrent/include/libtorrent/copy_ptr.hpp \
    libtorrent/include/libtorrent/create_torrent.hpp \
    libtorrent/include/libtorrent/deadline_timer.hpp \
    libtorrent/include/libtorrent/debug.hpp \
    libtorrent/include/libtorrent/disk_buffer_holder.hpp \
    libtorrent/include/libtorrent/disk_buffer_pool.hpp \
    libtorrent/include/libtorrent/disk_io_thread.hpp \
    libtorrent/include/libtorrent/entry.hpp \
    libtorrent/include/libtorrent/enum_net.hpp \
    libtorrent/include/libtorrent/error.hpp \
    libtorrent/include/libtorrent/error_code.hpp \
    libtorrent/include/libtorrent/escape_string.hpp \
    libtorrent/include/libtorrent/extensions.hpp \
    libtorrent/include/libtorrent/file.hpp \
    libtorrent/include/libtorrent/file_pool.hpp \
    libtorrent/include/libtorrent/file_storage.hpp \
    libtorrent/include/libtorrent/fingerprint.hpp \
    libtorrent/include/libtorrent/GeoIP.h \
    libtorrent/include/libtorrent/gzip.hpp \
    libtorrent/include/libtorrent/hasher.hpp \
    libtorrent/include/libtorrent/http_connection.hpp \
    libtorrent/include/libtorrent/http_parser.hpp \
    libtorrent/include/libtorrent/http_seed_connection.hpp \
    libtorrent/include/libtorrent/http_stream.hpp \
    libtorrent/include/libtorrent/http_tracker_connection.hpp \
    libtorrent/include/libtorrent/i2p_stream.hpp \
    libtorrent/include/libtorrent/identify_client.hpp \
    libtorrent/include/libtorrent/instantiate_connection.hpp \
    libtorrent/include/libtorrent/intrusive_ptr_base.hpp \
    libtorrent/include/libtorrent/invariant_check.hpp \
    libtorrent/include/libtorrent/io.hpp \
    libtorrent/include/libtorrent/io_service.hpp \
    libtorrent/include/libtorrent/io_service_fwd.hpp \
    libtorrent/include/libtorrent/ip_filter.hpp \
    libtorrent/include/libtorrent/ip_voter.hpp \
    libtorrent/include/libtorrent/lazy_entry.hpp \
    libtorrent/include/libtorrent/lsd.hpp \
    libtorrent/include/libtorrent/magnet_uri.hpp \
    libtorrent/include/libtorrent/max.hpp \
    libtorrent/include/libtorrent/natpmp.hpp \
    libtorrent/include/libtorrent/packet_buffer.hpp \
    libtorrent/include/libtorrent/parse_url.hpp \
    libtorrent/include/libtorrent/pch.hpp \
    libtorrent/include/libtorrent/pe_crypto.hpp \
    libtorrent/include/libtorrent/peer.hpp \
    libtorrent/include/libtorrent/peer_connection.hpp \
    libtorrent/include/libtorrent/peer_id.hpp \
    libtorrent/include/libtorrent/peer_info.hpp \
    libtorrent/include/libtorrent/peer_request.hpp \
    libtorrent/include/libtorrent/piece_block_progress.hpp \
    libtorrent/include/libtorrent/piece_picker.hpp \
    libtorrent/include/libtorrent/policy.hpp \
    libtorrent/include/libtorrent/proxy_base.hpp \
    libtorrent/include/libtorrent/ptime.hpp \
    libtorrent/include/libtorrent/puff.hpp \
    libtorrent/include/libtorrent/random.hpp \
    libtorrent/include/libtorrent/rsa.hpp \
    libtorrent/include/libtorrent/rss.hpp \
    libtorrent/include/libtorrent/session.hpp \
    libtorrent/include/libtorrent/session_settings.hpp \
    libtorrent/include/libtorrent/session_status.hpp \
    libtorrent/include/libtorrent/settings.hpp \
    libtorrent/include/libtorrent/size_type.hpp \
    libtorrent/include/libtorrent/sliding_average.hpp \
    libtorrent/include/libtorrent/socket.hpp \
    libtorrent/include/libtorrent/socket_io.hpp \
    libtorrent/include/libtorrent/socket_type.hpp \
    libtorrent/include/libtorrent/socket_type_fwd.hpp \
    libtorrent/include/libtorrent/socks5_stream.hpp \
    libtorrent/include/libtorrent/ssl_stream.hpp \
    libtorrent/include/libtorrent/stat.hpp \
    libtorrent/include/libtorrent/storage.hpp \
    libtorrent/include/libtorrent/storage_defs.hpp \
    libtorrent/include/libtorrent/string_util.hpp \
    libtorrent/include/libtorrent/struct_debug.hpp \
    libtorrent/include/libtorrent/thread.hpp \
    libtorrent/include/libtorrent/time.hpp \
    libtorrent/include/libtorrent/timestamp_history.hpp \
    libtorrent/include/libtorrent/tommath.h \
    libtorrent/include/libtorrent/tommath_class.h \
    libtorrent/include/libtorrent/tommath_superclass.h \
    libtorrent/include/libtorrent/torrent.hpp \
    libtorrent/include/libtorrent/torrent_handle.hpp \
    libtorrent/include/libtorrent/torrent_info.hpp \
    libtorrent/include/libtorrent/tracker_manager.hpp \
    libtorrent/include/libtorrent/udp_socket.hpp \
    libtorrent/include/libtorrent/udp_tracker_connection.hpp \
    libtorrent/include/libtorrent/union_endpoint.hpp \
    libtorrent/include/libtorrent/upnp.hpp \
    libtorrent/include/libtorrent/utf8.hpp \
    libtorrent/include/libtorrent/utp_socket_manager.hpp \
    libtorrent/include/libtorrent/utp_stream.hpp \
    libtorrent/include/libtorrent/version.hpp \
    libtorrent/include/libtorrent/web_connection_base.hpp \
    libtorrent/include/libtorrent/web_peer_connection.hpp \
    libtorrent/include/libtorrent/xml_parse.hpp \
    libtorrent/test/dht_server.hpp \
    libtorrent/test/peer_server.hpp \
    libtorrent/test/setup_transfer.hpp \
    libtorrent/test/test.hpp \
    src/leveldb/db/builder.h \
    src/leveldb/db/db_impl.h \
    src/leveldb/db/db_iter.h \
    src/leveldb/db/dbformat.h \
    src/leveldb/db/filename.h \
    src/leveldb/db/log_format.h \
    src/leveldb/db/log_reader.h \
    src/leveldb/db/log_writer.h \
    src/leveldb/db/memtable.h \
    src/leveldb/db/skiplist.h \
    src/leveldb/db/snapshot.h \
    src/leveldb/db/table_cache.h \
    src/leveldb/db/version_edit.h \
    src/leveldb/db/version_set.h \
    src/leveldb/db/write_batch_internal.h \
    src/leveldb/helpers/memenv/memenv.h \
    src/leveldb/include/leveldb/c.h \
    src/leveldb/include/leveldb/cache.h \
    src/leveldb/include/leveldb/comparator.h \
    src/leveldb/include/leveldb/db.h \
    src/leveldb/include/leveldb/env.h \
    src/leveldb/include/leveldb/filter_policy.h \
    src/leveldb/include/leveldb/iterator.h \
    src/leveldb/include/leveldb/options.h \
    src/leveldb/include/leveldb/slice.h \
    src/leveldb/include/leveldb/status.h \
    src/leveldb/include/leveldb/table.h \
    src/leveldb/include/leveldb/table_builder.h \
    src/leveldb/include/leveldb/write_batch.h \
    src/leveldb/port/win/stdint.h \
    src/leveldb/port/atomic_pointer.h \
    src/leveldb/port/port.h \
    src/leveldb/port/port_example.h \
    src/leveldb/port/port_posix.h \
    src/leveldb/port/port_win.h \
    src/leveldb/port/thread_annotations.h \
    src/leveldb/table/block.h \
    src/leveldb/table/block_builder.h \
    src/leveldb/table/filter_block.h \
    src/leveldb/table/format.h \
    src/leveldb/table/iterator_wrapper.h \
    src/leveldb/table/merger.h \
    src/leveldb/table/two_level_iterator.h \
    src/leveldb/util/arena.h \
    src/leveldb/util/coding.h \
    src/leveldb/util/crc32c.h \
    src/leveldb/util/hash.h \
    src/leveldb/util/histogram.h \
    src/leveldb/util/logging.h \
    src/leveldb/util/mutexlock.h \
    src/leveldb/util/posix_logger.h \
    src/leveldb/util/random.h \
    src/leveldb/util/testharness.h \
    src/leveldb/util/testutil.h \
    src/qt/aboutdialog.h \
    src/qt/addressbookpage.h \
    src/qt/addresstablemodel.h \
    src/qt/askpassphrasedialog.h \
    src/qt/bitcoinaddressvalidator.h \
    src/qt/bitcoinamountfield.h \
    src/qt/bitcoingui.h \
    src/qt/bitcoinunits.h \
    src/qt/clientmodel.h \
    src/qt/csvmodelwriter.h \
    src/qt/editaddressdialog.h \
    src/qt/guiconstants.h \
    src/qt/guiutil.h \
    src/qt/monitoreddatamapper.h \
    src/qt/notificator.h \
    src/qt/optionsdialog.h \
    src/qt/optionsmodel.h \
    src/qt/overviewpage.h \
    src/qt/paymentserver.h \
    src/qt/qvalidatedlineedit.h \
    src/qt/qvaluecombobox.h \
    src/qt/rpcconsole.h \
    src/qt/sendcoinsdialog.h \
    src/qt/sendcoinsentry.h \
    src/qt/signverifymessagedialog.h \
    src/qt/splashscreen.h \
    src/qt/transactiondesc.h \
    src/qt/transactiondescdialog.h \
    src/qt/transactionfilterproxy.h \
    src/qt/transactionrecord.h \
    src/qt/transactiontablemodel.h \
    src/qt/transactionview.h \
    src/qt/walletframe.h \
    src/qt/walletmodel.h \
    src/qt/walletstack.h \
    src/qt/walletview.h \
    src/accumunet.h

#    src/qt/bitcoingui.h
#    src/qt/transactiontablemodel.h \
#    src/qt/addresstablemodel.h \
#    src/qt/optionsdialog.h \
#    src/qt/sendcoinsdialog.h \
#    src/qt/addressbookpage.h \
#    src/qt/signverifymessagedialog.h \
#    src/qt/aboutdialog.h \
#    src/qt/editaddressdialog.h \
#    src/qt/bitcoinaddressvalidator.h \
#    src/qt/clientmodel.h \
#    src/qt/guiutil.h \
#    src/qt/transactionrecord.h \
#    src/qt/guiconstants.h \
#    src/qt/optionsmodel.h \
#    src/qt/monitoreddatamapper.h \
#    src/qt/transactiondesc.h \
#    src/qt/transactiondescdialog.h \
#    src/qt/bitcoinamountfield.h \
#    src/qt/transactionfilterproxy.h \
#    src/qt/transactionview.h \
#    src/qt/walletmodel.h \
#    src/qt/walletview.h \
#    src/qt/walletstack.h \
#    src/qt/walletframe.h \
#    src/qt/overviewpage.h \
#    src/qt/csvmodelwriter.h \
#    src/qt/sendcoinsentry.h \
#    src/qt/qvalidatedlineedit.h \
#    src/qt/bitcoinunits.h \
#    src/qt/qvaluecombobox.h \
#    src/qt/askpassphrasedialog.h \
#    src/qt/notificator.h \
#    src/qt/paymentserver.h \
#    src/qt/rpcconsole.h \
#    src/qt/splashscreen.h

SOURCES += \ #src/qt/bitcoin.cpp \
    src/bitcoind.cpp \
    src/alert.cpp \
    src/chainparams.cpp \
    src/version.cpp \
    src/sync.cpp \
    src/util.cpp \
    src/hash.cpp \
    src/netbase.cpp \
    src/key.cpp \
    src/script.cpp \
    src/core.cpp \
    src/main.cpp \
    src/init.cpp \
    src/net.cpp \
    src/bloom.cpp \
    src/checkpoints.cpp \
    src/softcheckpoint.cpp \
    src/addrman.cpp \
    src/db.cpp \
    src/walletdb.cpp \
    src/wallet.cpp \
    src/keystore.cpp \
    src/bitcoinrpc.cpp \
    src/rpcdump.cpp \
    src/rpcnet.cpp \
    src/rpcmining.cpp \
    src/rpcwallet.cpp \
    src/rpcblockchain.cpp \
    src/rpcrawtransaction.cpp \
    src/crypter.cpp \
    src/protocol.cpp \
    src/noui.cpp \
    src/leveldb.cpp \
    src/txdb.cpp \
    src/scrypt.cpp \
    src/dhtproxy.cpp \
    src/twister.cpp \
    src/twister_rss.cpp \
    src/twister_utils.cpp \
    libtorrent/examples/client_test.cpp \
    libtorrent/examples/connection_tester.cpp \
    libtorrent/examples/dump_torrent.cpp \
    libtorrent/examples/fragmentation_test.cpp \
    libtorrent/examples/make_torrent.cpp \
    libtorrent/examples/rss_reader.cpp \
    libtorrent/examples/simple_client.cpp \
    libtorrent/examples/upnp_test.cpp \
    libtorrent/examples/utp_test.cpp \
    libtorrent/src/kademlia/dht_get.cpp \
    libtorrent/src/kademlia/dht_tracker.cpp \
    libtorrent/src/kademlia/find_data.cpp \
    libtorrent/src/kademlia/logging.cpp \
    libtorrent/src/kademlia/node.cpp \
    libtorrent/src/kademlia/node_id.cpp \
    libtorrent/src/kademlia/refresh.cpp \
    libtorrent/src/kademlia/routing_table.cpp \
    libtorrent/src/kademlia/rpc_manager.cpp \
    libtorrent/src/kademlia/traversal_algorithm.cpp \
    libtorrent/src/alert.cpp \
    libtorrent/src/alert_manager.cpp \
    libtorrent/src/allocator.cpp \
    libtorrent/src/asio.cpp \
    libtorrent/src/asio_ssl.cpp \
    libtorrent/src/assert.cpp \
    libtorrent/src/bandwidth_limit.cpp \
    libtorrent/src/bandwidth_manager.cpp \
    libtorrent/src/bandwidth_queue_entry.cpp \
    libtorrent/src/bloom_filter.cpp \
    libtorrent/src/broadcast_socket.cpp \
    libtorrent/src/bt_peer_connection.cpp \
    libtorrent/src/chained_buffer.cpp \
    libtorrent/src/connection_queue.cpp \
    libtorrent/src/ConvertUTF.cpp \
    libtorrent/src/create_torrent.cpp \
    libtorrent/src/disk_buffer_holder.cpp \
    libtorrent/src/disk_buffer_pool.cpp \
    libtorrent/src/disk_io_thread.cpp \
    libtorrent/src/entry.cpp \
    libtorrent/src/enum_net.cpp \
    libtorrent/src/error_code.cpp \
    libtorrent/src/escape_string.cpp \
    libtorrent/src/file.cpp \
    libtorrent/src/file_pool.cpp \
    libtorrent/src/file_storage.cpp \
    libtorrent/src/gzip.cpp \
    libtorrent/src/hasher.cpp \
    libtorrent/src/http_connection.cpp \
    libtorrent/src/http_parser.cpp \
    libtorrent/src/http_seed_connection.cpp \
    libtorrent/src/http_stream.cpp \
    libtorrent/src/http_tracker_connection.cpp \
    libtorrent/src/i2p_stream.cpp \
    libtorrent/src/identify_client.cpp \
    libtorrent/src/instantiate_connection.cpp \
    libtorrent/src/ip_filter.cpp \
    libtorrent/src/ip_voter.cpp \
    libtorrent/src/lazy_bdecode.cpp \
    libtorrent/src/logger.cpp \
    libtorrent/src/lsd.cpp \
    libtorrent/src/lt_trackers.cpp \
    libtorrent/src/magnet_uri.cpp \
    libtorrent/src/metadata_transfer.cpp \
    libtorrent/src/natpmp.cpp \
    libtorrent/src/packet_buffer.cpp \
    libtorrent/src/parse_url.cpp \
    libtorrent/src/pe_crypto.cpp \
    libtorrent/src/peer_connection.cpp \
    libtorrent/src/piece_picker.cpp \
    libtorrent/src/policy.cpp \
    libtorrent/src/puff.cpp \
    libtorrent/src/random.cpp \
    libtorrent/src/rsa.cpp \
    libtorrent/src/rss.cpp \
    libtorrent/src/session.cpp \
    libtorrent/src/session_impl.cpp \
    libtorrent/src/settings.cpp \
    libtorrent/src/sha1.cpp \
    libtorrent/src/smart_ban.cpp \
    libtorrent/src/socket_io.cpp \
    libtorrent/src/socket_type.cpp \
    libtorrent/src/socks5_stream.cpp \
    libtorrent/src/stat.cpp \
    libtorrent/src/storage.cpp \
    libtorrent/src/string_util.cpp \
    libtorrent/src/thread.cpp \
    libtorrent/src/time.cpp \
    libtorrent/src/timestamp_history.cpp \
    libtorrent/src/torrent.cpp \
    libtorrent/src/torrent_handle.cpp \
    libtorrent/src/torrent_info.cpp \
    libtorrent/src/tracker_manager.cpp \
    libtorrent/src/udp_socket.cpp \
    libtorrent/src/udp_tracker_connection.cpp \
    libtorrent/src/upnp.cpp \
    libtorrent/src/ut_metadata.cpp \
    libtorrent/src/ut_pex.cpp \
    libtorrent/src/utf8.cpp \
    libtorrent/src/utp_socket_manager.cpp \
    libtorrent/src/utp_stream.cpp \
    libtorrent/src/web_connection_base.cpp \
    libtorrent/src/web_peer_connection.cpp \
    libtorrent/test/dht_server.cpp \
    libtorrent/test/enum_if.cpp \
    libtorrent/test/main.cpp \
    libtorrent/test/peer_server.cpp \
    libtorrent/test/setup_transfer.cpp \
    libtorrent/test/test_auto_unchoke.cpp \
    libtorrent/test/test_bandwidth_limiter.cpp \
    libtorrent/test/test_bdecode_performance.cpp \
    libtorrent/test/test_bencoding.cpp \
    libtorrent/test/test_buffer.cpp \
    libtorrent/test/test_checking.cpp \
    libtorrent/test/test_dht.cpp \
    libtorrent/test/test_fast_extension.cpp \
    libtorrent/test/test_file.cpp \
    libtorrent/test/test_file_storage.cpp \
    libtorrent/test/test_hasher.cpp \
    libtorrent/test/test_http_connection.cpp \
    libtorrent/test/test_ip_filter.cpp \
    libtorrent/test/test_lsd.cpp \
    libtorrent/test/test_metadata_extension.cpp \
    libtorrent/test/test_natpmp.cpp \
    libtorrent/test/test_pe_crypto.cpp \
    libtorrent/test/test_peer_priority.cpp \
    libtorrent/test/test_pex.cpp \
    libtorrent/test/test_piece_picker.cpp \
    libtorrent/test/test_primitives.cpp \
    libtorrent/test/test_privacy.cpp \
    libtorrent/test/test_rss.cpp \
    libtorrent/test/test_session.cpp \
    libtorrent/test/test_storage.cpp \
    libtorrent/test/test_swarm.cpp \
    libtorrent/test/test_threads.cpp \
    libtorrent/test/test_torrent.cpp \
    libtorrent/test/test_torrent_parse.cpp \
    libtorrent/test/test_tracker.cpp \
    libtorrent/test/test_trackers_extension.cpp \
    libtorrent/test/test_transfer.cpp \
    libtorrent/test/test_upnp.cpp \
    libtorrent/test/test_utp.cpp \
    libtorrent/test/test_web_seed.cpp \
    libtorrent/tools/parse_hash_fails.cpp \
    libtorrent/tools/parse_request_log.cpp \
    src/json/json_spirit_reader.cpp \
    src/json/json_spirit_value.cpp \
    src/json/json_spirit_writer.cpp \
    src/leveldb/db/builder.cc \
    src/leveldb/db/c.cc \
    src/leveldb/db/corruption_test.cc \
    src/leveldb/db/db_bench.cc \
    src/leveldb/db/db_impl.cc \
    src/leveldb/db/db_iter.cc \
    src/leveldb/db/db_test.cc \
    src/leveldb/db/dbformat.cc \
    src/leveldb/db/dbformat_test.cc \
    src/leveldb/db/filename.cc \
    src/leveldb/db/filename_test.cc \
    src/leveldb/db/leveldb_main.cc \
    src/leveldb/db/log_reader.cc \
    src/leveldb/db/log_test.cc \
    src/leveldb/db/log_writer.cc \
    src/leveldb/db/memtable.cc \
    src/leveldb/db/repair.cc \
    src/leveldb/db/skiplist_test.cc \
    src/leveldb/db/table_cache.cc \
    src/leveldb/db/version_edit.cc \
    src/leveldb/db/version_edit_test.cc \
    src/leveldb/db/version_set.cc \
    src/leveldb/db/version_set_test.cc \
    src/leveldb/db/write_batch.cc \
    src/leveldb/db/write_batch_test.cc \
    src/leveldb/doc/bench/db_bench_sqlite3.cc \
    src/leveldb/doc/bench/db_bench_tree_db.cc \
    src/leveldb/helpers/memenv/memenv.cc \
    src/leveldb/helpers/memenv/memenv_test.cc \
    src/leveldb/port/port_posix.cc \
    src/leveldb/port/port_win.cc \
    src/leveldb/table/block.cc \
    src/leveldb/table/block_builder.cc \
    src/leveldb/table/filter_block.cc \
    src/leveldb/table/filter_block_test.cc \
    src/leveldb/table/format.cc \
    src/leveldb/table/iterator.cc \
    src/leveldb/table/merger.cc \
    src/leveldb/table/table.cc \
    src/leveldb/table/table_builder.cc \
    src/leveldb/table/table_test.cc \
    src/leveldb/table/two_level_iterator.cc \
    src/leveldb/util/arena.cc \
    src/leveldb/util/arena_test.cc \
    src/leveldb/util/bloom.cc \
    src/leveldb/util/bloom_test.cc \
    src/leveldb/util/cache.cc \
    src/leveldb/util/cache_test.cc \
    src/leveldb/util/coding.cc \
    src/leveldb/util/coding_test.cc \
    src/leveldb/util/comparator.cc \
    src/leveldb/util/crc32c.cc \
    src/leveldb/util/crc32c_test.cc \
    src/leveldb/util/env.cc \
    src/leveldb/util/env_posix.cc \
    src/leveldb/util/env_test.cc \
    src/leveldb/util/env_win.cc \
    src/leveldb/util/filter_policy.cc \
    src/leveldb/util/hash.cc \
    src/leveldb/util/histogram.cc \
    src/leveldb/util/logging.cc \
    src/leveldb/util/options.cc \
    src/leveldb/util/status.cc \
    src/leveldb/util/testharness.cc \
    src/leveldb/util/testutil.cc \
    src/qt/aboutdialog.cpp \
    src/qt/addressbookpage.cpp \
    src/qt/addresstablemodel.cpp \
    src/qt/askpassphrasedialog.cpp \
    src/qt/bitcoin.cpp \
    src/qt/bitcoinaddressvalidator.cpp \
    src/qt/bitcoinamountfield.cpp \
    src/qt/bitcoingui.cpp \
    src/qt/bitcoinstrings.cpp \
    src/qt/bitcoinunits.cpp \
    src/qt/clientmodel.cpp \
    src/qt/csvmodelwriter.cpp \
    src/qt/editaddressdialog.cpp \
    src/qt/guiutil.cpp \
    src/qt/monitoreddatamapper.cpp \
    src/qt/notificator.cpp \
    src/qt/optionsdialog.cpp \
    src/qt/optionsmodel.cpp \
    src/qt/overviewpage.cpp \
    src/qt/paymentserver.cpp \
    src/qt/qvalidatedlineedit.cpp \
    src/qt/qvaluecombobox.cpp \
    src/qt/rpcconsole.cpp \
    src/qt/sendcoinsdialog.cpp \
    src/qt/sendcoinsentry.cpp \
    src/qt/signverifymessagedialog.cpp \
    src/qt/splashscreen.cpp \
    src/qt/transactiondesc.cpp \
    src/qt/transactiondescdialog.cpp \
    src/qt/transactionfilterproxy.cpp \
    src/qt/transactionrecord.cpp \
    src/qt/transactiontablemodel.cpp \
    src/qt/transactionview.cpp \
    src/qt/walletframe.cpp \
    src/qt/walletmodel.cpp \
    src/qt/walletstack.cpp \
    src/qt/walletview.cpp \
    src/accumunet.cpp \
    src/scrypt-sse2.cpp \
    libtorrent/src/GeoIP.c \
    libtorrent/src/mpi.c \
    src/leveldb/db/c_test.c

#    src/qt/guiutil.cpp \
#    src/qt/bitcoingui.cpp \
#    src/qt/transactiontablemodel.cpp \
#    src/qt/addresstablemodel.cpp \
#    src/qt/optionsdialog.cpp \
#    src/qt/sendcoinsdialog.cpp \
#    src/qt/addressbookpage.cpp \
#    src/qt/signverifymessagedialog.cpp \
#    src/qt/aboutdialog.cpp \
#    src/qt/editaddressdialog.cpp \
#    src/qt/bitcoinaddressvalidator.cpp \
#    src/qt/clientmodel.cpp \
#    src/qt/transactionrecord.cpp \
#    src/qt/optionsmodel.cpp \
#    src/qt/monitoreddatamapper.cpp \
#    src/qt/transactiondesc.cpp \
#    src/qt/transactiondescdialog.cpp \
#    src/qt/bitcoinstrings.cpp \
#    src/qt/bitcoinamountfield.cpp \
#    src/qt/transactionfilterproxy.cpp \
#    src/qt/transactionview.cpp \
#    src/qt/walletmodel.cpp \
#    src/qt/walletview.cpp \
#    src/qt/walletstack.cpp \
#    src/qt/walletframe.cpp \
#    src/qt/overviewpage.cpp \
#    src/qt/csvmodelwriter.cpp \
#    src/qt/sendcoinsentry.cpp \
#    src/qt/qvalidatedlineedit.cpp \
#    src/qt/bitcoinunits.cpp \
#    src/qt/qvaluecombobox.cpp \
#    src/qt/askpassphrasedialog.cpp \
#    src/qt/notificator.cpp \
#    src/qt/paymentserver.cpp \
#    src/qt/rpcconsole.cpp \
#    src/qt/splashscreen.cpp

#RESOURCES += src/qt/bitcoin.qrc

#FORMS += src/qt/forms/sendcoinsdialog.ui \
#    src/qt/forms/addressbookpage.ui \
#    src/qt/forms/signverifymessagedialog.ui \
#    src/qt/forms/aboutdialog.ui \
#    src/qt/forms/editaddressdialog.ui \
#    src/qt/forms/transactiondescdialog.ui \
#    src/qt/forms/overviewpage.ui \
#    src/qt/forms/sendcoinsentry.ui \
#    src/qt/forms/askpassphrasedialog.ui \
#    src/qt/forms/rpcconsole.ui \
#    src/qt/forms/optionsdialog.ui

contains(USE_QRCODE, 1) {
HEADERS += src/qt/qrcodedialog.h
SOURCES += src/qt/qrcodedialog.cpp
FORMS += src/qt/forms/qrcodedialog.ui
}

contains(BITCOIN_QT_TEST, 1) {
SOURCES += src/qt/test/test_main.cpp \
    src/qt/test/uritests.cpp
HEADERS += src/qt/test/uritests.h
DEPENDPATH += src/qt/test
QT += testlib
TARGET = bitcoin-qt_test
DEFINES += BITCOIN_QT_TEST
  macx: CONFIG -= app_bundle
}

contains(USE_SSE2, 1) {
DEFINES += USE_SSE2
gccsse2.input  = SOURCES_SSE2
gccsse2.output = $$PWD/build/${QMAKE_FILE_BASE}.o
gccsse2.commands = $(CXX) -c $(CXXFLAGS) $(INCPATH) -o ${QMAKE_FILE_OUT} ${QMAKE_FILE_NAME} -msse2 -mstackrealign
QMAKE_EXTRA_COMPILERS += gccsse2
SOURCES_SSE2 += src/scrypt-sse2.cpp
}

# Todo: Remove this line when switching to Qt5, as that option was removed
CODECFORTR = UTF-8

# for lrelease/lupdate
# also add new translations to src/qt/bitcoin.qrc under translations/
TRANSLATIONS = $$files(src/qt/locale/bitcoin_*.ts)

isEmpty(QMAKE_LRELEASE) {
    win32:QMAKE_LRELEASE = $$[QT_INSTALL_BINS]\\lrelease.exe
    else:QMAKE_LRELEASE = $$[QT_INSTALL_BINS]/lrelease
}
isEmpty(QM_DIR):QM_DIR = $$PWD/src/qt/locale
# automatically build translations, so they can be included in resource file
TSQM.name = lrelease ${QMAKE_FILE_IN}
TSQM.input = TRANSLATIONS
TSQM.output = $$QM_DIR/${QMAKE_FILE_BASE}.qm
TSQM.commands = $$QMAKE_LRELEASE ${QMAKE_FILE_IN} -qm ${QMAKE_FILE_OUT}
TSQM.CONFIG = no_link
QMAKE_EXTRA_COMPILERS += TSQM

# "Other files" to show in Qt Creator
OTHER_FILES += README.md \
    doc/*.txt \
    doc/*.md \
    src/qt/res/bitcoin-qt.rc \
    src/test/*.cpp \
    src/test/*.h \
    src/qt/test/*.cpp \
    src/qt/test/*.h

# platform specific defaults, if not overridden on command line
isEmpty(BOOST_LIB_SUFFIX) {
    macx:BOOST_LIB_SUFFIX = -mt
    win32:BOOST_LIB_SUFFIX = -mgw44-mt-s-1_50
}

isEmpty(BOOST_THREAD_LIB_SUFFIX) {
    BOOST_THREAD_LIB_SUFFIX = $$BOOST_LIB_SUFFIX
}

isEmpty(BDB_LIB_PATH) {
    macx:BDB_LIB_PATH = /opt/local/lib/db48
}

isEmpty(BDB_LIB_SUFFIX) {
    macx:BDB_LIB_SUFFIX = -4.8
}

isEmpty(BDB_INCLUDE_PATH) {
    macx:BDB_INCLUDE_PATH = /opt/local/include/db48
}

isEmpty(BOOST_LIB_PATH) {
    macx:BOOST_LIB_PATH = /opt/local/lib
}

isEmpty(BOOST_INCLUDE_PATH) {
    macx:BOOST_INCLUDE_PATH = /opt/local/include
}

win32:DEFINES += WIN32
win32:RC_FILE = src/qt/res/bitcoin-qt.rc

win32:!contains(MINGW_THREAD_BUGFIX, 0) {
    # At least qmake's win32-g++-cross profile is missing the -lmingwthrd
    # thread-safety flag. GCC has -mthreads to enable this, but it doesn't
    # work with static linking. -lmingwthrd must come BEFORE -lmingw, so
    # it is prepended to QMAKE_LIBS_QT_ENTRY.
    # It can be turned off with MINGW_THREAD_BUGFIX=0, just in case it causes
    # any problems on some untested qmake profile now or in the future.
    DEFINES += _MT
    QMAKE_LIBS_QT_ENTRY = -lmingwthrd $$QMAKE_LIBS_QT_ENTRY
}

!win32:!macx {
    DEFINES += LINUX
    LIBS += -lrt
    # _FILE_OFFSET_BITS=64 lets 32-bit fopen transparently support large files.
    DEFINES += _FILE_OFFSET_BITS=64
}

macx:HEADERS += src/qt/macdockiconhandler.h src/qt/macnotificationhandler.h
macx:OBJECTIVE_SOURCES += src/qt/macdockiconhandler.mm src/qt/macnotificationhandler.mm
macx:LIBS += -framework Foundation -framework ApplicationServices -framework AppKit -framework CoreServices
macx:DEFINES += MAC_OSX MSG_NOSIGNAL=0
macx:ICON = src/qt/res/icons/bitcoin.icns
macx:QMAKE_CFLAGS_THREAD += -pthread
macx:QMAKE_LFLAGS_THREAD += -pthread
macx:QMAKE_CXXFLAGS_THREAD += -pthread
macx:QMAKE_INFO_PLIST = share/qt/Info.plist

# Set libraries and includes at end, to use platform-defined defaults if not overridden
INCLUDEPATH += $$BOOST_INCLUDE_PATH $$BDB_INCLUDE_PATH $$OPENSSL_INCLUDE_PATH $$QRENCODE_INCLUDE_PATH
LIBS += $$join(BOOST_LIB_PATH,,-L,) $$join(BDB_LIB_PATH,,-L,) $$join(OPENSSL_LIB_PATH,,-L,) $$join(QRENCODE_LIB_PATH,,-L,)
LIBS += -lssl -lcrypto -ldb_cxx$$BDB_LIB_SUFFIX
# -lgdi32 has to happen after -lcrypto (see  #681)
win32:LIBS += -lws2_32 -lshlwapi -lmswsock -lole32 -loleaut32 -luuid -lgdi32
LIBS += -lboost_system$$BOOST_LIB_SUFFIX -lboost_filesystem$$BOOST_LIB_SUFFIX -lboost_program_options$$BOOST_LIB_SUFFIX -lboost_thread$$BOOST_THREAD_LIB_SUFFIX -lboost_locale$$BOOST_THREAD_LIB_SUFFIX
win32:LIBS += -lboost_chrono$$BOOST_LIB_SUFFIX
macx:LIBS += -lboost_chrono$$BOOST_LIB_SUFFIX

contains(RELEASE, 1) {
    !win32:!macx {
        # Linux: turn dynamic linking back on for c/c++ runtime libraries
        LIBS += -Wl,-Bdynamic
    }
}

system($$QMAKE_LRELEASE -silent $$TRANSLATIONS)
