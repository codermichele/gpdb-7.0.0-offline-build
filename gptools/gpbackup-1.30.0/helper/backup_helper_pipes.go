package helper

import (
	"bufio"
	"compress/gzip"
	"io"

	"github.com/klauspost/compress/zstd"
)

type BackupPipeWriterCloser interface {
	io.Writer
	io.Closer
}

type CommonBackupPipeWriterCloser struct {
	writeHandle io.WriteCloser
	bufIoWriter *bufio.Writer
	finalWriter io.Writer
}

func (cPipe CommonBackupPipeWriterCloser) Write(p []byte) (n int, err error) {
	return cPipe.finalWriter.Write(p)
}

// Never returns error, suppressing them instead
func (cPipe CommonBackupPipeWriterCloser) Close() error {
	_ = cPipe.bufIoWriter.Flush()
	_ = cPipe.writeHandle.Close()
	return nil
}

func NewCommonBackupPipeWriterCloser(writeHandle io.WriteCloser) (cPipe CommonBackupPipeWriterCloser) {
	cPipe.writeHandle = writeHandle
	cPipe.bufIoWriter = bufio.NewWriter(cPipe.writeHandle)
	cPipe.finalWriter = cPipe.bufIoWriter
	return
}

type GZipBackupPipeWriterCloser struct {
	cPipe      CommonBackupPipeWriterCloser
	gzipWriter *gzip.Writer
}

func (gzPipe GZipBackupPipeWriterCloser) Write(p []byte) (n int, err error) {
	return gzPipe.gzipWriter.Write(p)
}

// Returns errors from underlying common writer only
func (gzPipe GZipBackupPipeWriterCloser) Close() error {
	_ = gzPipe.gzipWriter.Close()
	return gzPipe.cPipe.Close()
}

func NewGZipBackupPipeWriterCloser(writeHandle io.WriteCloser, compressLevel int) (gzPipe GZipBackupPipeWriterCloser, err error) {
	gzPipe.cPipe = NewCommonBackupPipeWriterCloser(writeHandle)
	gzPipe.gzipWriter, err = gzip.NewWriterLevel(gzPipe.cPipe.bufIoWriter, compressLevel)
	if err != nil {
		gzPipe.cPipe.Close()
	}
	return
}

type ZSTDBackupPipeWriterCloser struct {
	cPipe       CommonBackupPipeWriterCloser
	zstdEncoder *zstd.Encoder
}

func (zstdPipe ZSTDBackupPipeWriterCloser) Write(p []byte) (n int, err error) {
	return zstdPipe.zstdEncoder.Write(p)
}

// Returns errors from underlying common writer only
func (zstdPipe ZSTDBackupPipeWriterCloser) Close() error {
	_ = zstdPipe.zstdEncoder.Close()
	return zstdPipe.cPipe.Close()
}

func NewZSTDBackupPipeWriterCloser(writeHandle io.WriteCloser, compressLevel int) (zstdPipe ZSTDBackupPipeWriterCloser, err error) {
	zstdPipe.cPipe = NewCommonBackupPipeWriterCloser(writeHandle)
	zstdPipe.zstdEncoder, err = zstd.NewWriter(zstdPipe.cPipe.bufIoWriter, zstd.WithEncoderLevel(zstd.EncoderLevelFromZstd(compressLevel)))
	if err != nil {
		zstdPipe.cPipe.Close()
	}
	return
}
