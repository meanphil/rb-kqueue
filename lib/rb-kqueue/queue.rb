module KQueue
  class Queue
    attr_reader :fd
    attr_reader :watchers

    def initialize
      @fd = Native.kqueue
      @watchers = {}
    end

    def watch_for_read(fd, &callback)
      fd = fd.fileno if fd.respond_to?(:fileno)
      Watcher::ReadWrite.new(self, fd, :read, callback)
    end

    def watch_for_socket_read(fd, low_water = nil, &callback)
      fd = fd.fileno if fd.respond_to?(:fileno)
      Watcher::SocketReadWrite.new(self, fd, :read, low_water, callback)
    end

    def watch_for_write(fd, &callback)
      fd = fd.fileno if fd.respond_to?(:fileno)
      Watcher::ReadWrite.new(self, fd, :write, callback)
    end

    def watch_for_socket_write(fd, low_water = nil, &callback)
      fd = fd.fileno if fd.respond_to?(:fileno)
      Watcher::SocketReadWrite.new(self, fd, :write, low_water, callback)
    end

    def watch_for_change(path, *flags, &callback)
      Watcher::VNode.new(self, path, flags, callback)
    end

    def run
      @stop = false
      process until @stop
    end

    def stop
      @stop = true
    end

    def process
      read_events.each {|event| event.callback!}
    end

    def read_events
      size = 1024
      eventlist = FFI::MemoryPointer.new(Native::KEvent, size)
      res = Native.kevent(@fd, nil, 0, eventlist, size, nil)

      KQueue.handle_error if res < 0
      (0...res).map {|i| KQueue::Event.new(Native::KEvent.new(eventlist[i]), self)}
    end
  end
end
