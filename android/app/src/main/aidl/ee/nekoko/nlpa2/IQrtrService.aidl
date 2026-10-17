package ee.nekoko.nlpa2;

/**
 * What the app asks a process of its own, started by the Shizuku server as the
 * `shell` user, to do with a socket on the QRTR bus.
 *
 * The app may not open one, and may not use one another process opened, so the
 * socket stays here and the app is given the four things a transport needs
 * from it: where it is addressed, one datagram out, one datagram in, and
 * closing it. An address on the bus is a node and a port rather than anything
 * Java can name, which is why the calls land in native code.
 */
interface IQrtrService {
    /**
     * Reserved for the Shizuku server, which calls it to stop the service.
     */
    void destroy() = 16777114;

    /**
     * Load the library the calls below land in.
     *
     * The service process is started from the app's code but has none of its
     * libraries, so the app says where they are: the directory the platform
     * would unpack them into, the package it can take them out of, and which
     * of the builds inside that package this device runs.
     */
    void prepare(in String libraryDir, in String apkPath, in String abi) = 1;

    /**
     * Open a socket on the bus, answering its descriptor.
     */
    int openBus() = 2;

    /**
     * The node that socket is bound to, which is where a lookup starts.
     */
    int busNode(int fd) = 3;

    /**
     * Send one datagram to an address on the bus.
     */
    void send(int fd, int node, int port, in byte[] data) = 4;

    /**
     * Wait for one datagram.
     *
     * The address it came from is in front of the message: node then port,
     * both 32 bit little endian, then the message itself. An empty answer
     * means nothing arrived in time.
     */
    byte[] receive(int fd, int timeoutMs) = 5;

    /**
     * Close a socket this service opened.
     */
    void closeBus(int fd) = 6;
    byte[] halAtr(int slot) = 7;
    byte[] halRead(int slot, in byte[] apdu) = 8;
    void halBeginDownload(int slot) = 9;
    void halEndDownload(int slot) = 10;
    byte[] halDownload(int slot, in byte[] payload, in int[] segmentLengths) = 11;
    void halStageDownload(int slot, in byte[] chunk, boolean first) = 12;
    byte[] halSwitchProfile(int slot, in byte[] iccid, in byte[] expectedEid, boolean enable) = 13;
    byte[] halRenameProfile(int slot, in byte[] iccid, in byte[] expectedEid, in byte[] nickname) = 14;
    byte[] halDeleteProfile(int slot, in byte[] iccid, in byte[] expectedEid) = 15;
    byte[] halRemoveNotification(int slot, int sequence, in byte[] expectedEid, in byte[] expectedResponse) = 16;
    void halOpenOwned(int slot) = 17;
    void halCloseOwned(int slot) = 18;
    void halUseBorrowed(int slot) = 19;
    // slot 0 conservatively invalidates both SIM slots; no card I/O.
    void halInvalidateSessions(int slot) = 20;
}
