// Revision 19846 is the following, where upstream moved src/webrtc to src/
// https://webrtc.googlesource.com/src/+/92ea95e34af5966555903026f45164afbd7e2088
#if WEBRTC_REVISION_NUMBER && WEBRTC_REVISION_NUMBER < 19846
  #include "webrtc/rtc_base/thread.h"
  #include "webrtc/p2p/base/basicpacketsocketfactory.h"
  #include "webrtc/api/peerconnectioninterface.h"
  #include "webrtc/api/test/fakeconstraints.h"
  #include "webrtc/media/engine/webrtcvideocapturerfactory.h"
  #include "webrtc/base/ssladapter.h"
  #include "webrtc/api/audio_codecs/builtin_audio_decoder_factory.h"
  #include "webrtc/api/audio_codecs/builtin_audio_encoder_factory.h"
#else
  #include "rtc_base/thread.h"
  #include "p2p/base/basicpacketsocketfactory.h"
  #include "api/peerconnectioninterface.h"
  #include "api/test/fakeconstraints.h"
  #include "media/engine/webrtcvideocapturerfactory.h"
  #include "rtc_base/ssladapter.h"
  #include "api/audio_codecs/builtin_audio_decoder_factory.h"
  #include "api/audio_codecs/builtin_audio_encoder_factory.h"
#endif


class VideoPacketSource : public cricket::VideoCapturer
{
public:
    VideoPacketSource()
    {
        std::vector<cricket::VideoFormat> formats;
        SetSupportedFormats(formats);
    }
    
    virtual cricket::CaptureState Start(const cricket::VideoFormat& capture_format) override { return cricket::CS_RUNNING; }
    virtual void Stop() override {};
    virtual bool GetPreferredFourccs(std::vector<uint32_t>* fourccs) override { return true; };
    virtual bool IsRunning() override { return true; };
    virtual bool IsScreencast() const override { return false; };
};


int main(int argc, char* argv[]) {

  // logging
  rtc::LogMessage::LogToDebug(rtc::LS_VERBOSE); // LS_VERBOSE, LS_INFO, LERROR

  rtc::InitializeSSL();

  // something from base
  rtc::Thread* thread = rtc::Thread::Current();

  // something from p2p
  std::unique_ptr<rtc::BasicPacketSocketFactory> socket_factory(
    new rtc::BasicPacketSocketFactory());

  // something from api
  rtc::scoped_refptr<webrtc::AudioEncoderFactory> audio_encoder_factory = webrtc::CreateBuiltinAudioEncoderFactory();
  rtc::scoped_refptr<webrtc::AudioDecoderFactory> audio_decoder_factory = webrtc::CreateBuiltinAudioDecoderFactory();
  rtc::scoped_refptr<webrtc::PeerConnectionFactoryInterface>
    peer_connection_factory = webrtc::CreatePeerConnectionFactory(audio_encoder_factory, audio_decoder_factory);

  // custom video source
  //VideoPacketSource video_source;

  // something from api/test
  webrtc::FakeConstraints constraints;

  // something from media/engine
  cricket::WebRtcVideoDeviceCapturerFactory factory;
  auto capturer = factory.Create(cricket::Device("", 0));
  // cricket::VideoCapturer* capturer = factory.Create(cricket::Device("", 0));

  return 0;
}
