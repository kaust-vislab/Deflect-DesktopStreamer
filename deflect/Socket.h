/*********************************************************************/
/* Copyright (c) 2015-2017, EPFL/Blue Brain Project                  */
/*                          Raphael Dumusc <raphael.dumusc@epfl.ch>  */
/*                          Daniel Nachbaur <daniel.nachbaur@epfl.ch>*/
/* All rights reserved.                                              */
/*                                                                   */
/* Redistribution and use in source and binary forms, with or        */
/* without modification, are permitted provided that the following   */
/* conditions are met:                                               */
/*                                                                   */
/*   1. Redistributions of source code must retain the above         */
/*      copyright notice, this list of conditions and the following  */
/*      disclaimer.                                                  */
/*                                                                   */
/*   2. Redistributions in binary form must reproduce the above      */
/*      copyright notice, this list of conditions and the following  */
/*      disclaimer in the documentation and/or other materials       */
/*      provided with the distribution.                              */
/*                                                                   */
/*    THIS  SOFTWARE  IS  PROVIDED  BY  THE  ECOLE  POLYTECHNIQUE    */
/*    FEDERALE DE LAUSANNE  ''AS IS''  AND ANY EXPRESS OR IMPLIED    */
/*    WARRANTIES, INCLUDING, BUT  NOT  LIMITED  TO,  THE  IMPLIED    */
/*    WARRANTIES OF MERCHANTABILITY AND FITNESS FOR  A PARTICULAR    */
/*    PURPOSE  ARE  DISCLAIMED.  IN  NO  EVENT  SHALL  THE  ECOLE    */
/*    POLYTECHNIQUE  FEDERALE  DE  LAUSANNE  OR  CONTRIBUTORS  BE    */
/*    LIABLE  FOR  ANY  DIRECT,  INDIRECT,  INCIDENTAL,  SPECIAL,    */
/*    EXEMPLARY,  OR  CONSEQUENTIAL  DAMAGES  (INCLUDING, BUT NOT    */
/*    LIMITED TO,  PROCUREMENT  OF  SUBSTITUTE GOODS OR SERVICES;    */
/*    LOSS OF USE, DATA, OR  PROFITS;  OR  BUSINESS INTERRUPTION)    */
/*    HOWEVER CAUSED AND  ON ANY THEORY OF LIABILITY,  WHETHER IN    */
/*    CONTRACT, STRICT LIABILITY,  OR TORT  (INCLUDING NEGLIGENCE    */
/*    OR OTHERWISE) ARISING  IN ANY WAY  OUT OF  THE USE OF  THIS    */
/*    SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.   */
/*                                                                   */
/* The views and conclusions contained in the software and           */
/* documentation are those of the authors and should not be          */
/* interpreted as representing official policies, either expressed   */
/* or implied, of Ecole polytechnique federale de Lausanne.          */
/*********************************************************************/

#ifndef DEFLECT_SOCKET_H
#define DEFLECT_SOCKET_H

#ifdef _WIN32
typedef __int32 int32_t;
#endif

#include <deflect/api.h>
#include <deflect/types.h>

#include <string>

#include <QByteArray>
#include <QMutex>
#include <QObject>


class QTcpSocket;

namespace deflect
{
/**
 * Represent a communication Socket for the Stream Library.
 */
class Socket : public QObject
{
    Q_OBJECT

public:
    /**
     * Construct a Socket and connect to host.
     * @param host The target host (IP address or hostname)
     * @param port The target port
     * @throw std::runtime_error if the socket could not connect
     */
    DEFLECT_API Socket(const std::string& host, unsigned short port);

    /** Destruct a Socket, disconnecting from host. */
    DEFLECT_API ~Socket() = default;

    /** Get the host passed to the constructor. */
    const std::string& getHost() const;

    /** Get the remote port the socket is connected to. */
    unsigned short getPort() const;

    /** Is the Socket connected */
    DEFLECT_API bool isConnected() const;

    /** @return the protocol version of the server. */
    int32_t getServerProtocolVersion() const;

    /**
     * Get the FileDescriptor for the Socket (for use by poll())
     * @return The file descriptor if available, otherwise return -1.
     */
    int getFileDescriptor() const;

    /**
     * Is there a pending message
     * @param messageSize Minimum size of the message
     */
    bool hasMessage(const size_t messageSize = 0) const;

    /**
     * Send a message.
     * @param messageHeader The message header
     * @param message The message data
     * @param waitForBytesWritten wait until the message is completely send; in
     *        case of multiple sends per frame it is advised to do this only
     *        once per frame
     * @return true if the message could be sent, false otherwise
     */
    bool send(const MessageHeader& messageHeader, const QByteArray& message,
              bool waitForBytesWritten);

    /**
     * Receive a message.
     * @param messageHeader The received message header
     * @param message The received message data
     * @return true if a message could be received, false otherwise
     */
    bool receive(MessageHeader& messageHeader, QByteArray& message);

signals:
    /** Signal that the socket has been disconnected. */
    void disconnected();

private:
    const std::string _host;
    QTcpSocket* _socket; // Child QObject
    mutable QMutex _socketMutex;
    int32_t _serverProtocolVersion;

    bool _receiveHeader(MessageHeader& messageHeader);
    void _connect(const std::string& host, const unsigned short port);
    bool _receiveProtocolVersion();
    bool _write(const QByteArray& data);
};
}

#endif
