package storage

import (
	"context"
	"fmt"
	"io"
	"path"
	"strings"

	"github.com/google/uuid"
	"github.com/minio/minio-go/v7"
	"github.com/minio/minio-go/v7/pkg/credentials"
)

const bucketName = "passenger-documents"

type MinIO struct {
	client *minio.Client
}

func New(endpoint, accessKey, secretKey string, useSSL bool) (*MinIO, error) {
	client, err := minio.New(endpoint, &minio.Options{
		Creds:  credentials.NewStaticV4(accessKey, secretKey, ""),
		Secure: useSSL,
	})
	if err != nil {
		return nil, err
	}

	ctx := context.Background()
	exists, err := client.BucketExists(ctx, bucketName)
	if err != nil {
		return nil, fmt.Errorf("check bucket: %w", err)
	}
	if !exists {
		if err := client.MakeBucket(ctx, bucketName, minio.MakeBucketOptions{}); err != nil {
			return nil, fmt.Errorf("create bucket: %w", err)
		}
	}

	return &MinIO{client: client}, nil
}

func (m *MinIO) UploadDocument(ctx context.Context, passengerID, docType, filename string, reader io.Reader, size int64, contentType string) (string, error) {
	ext := path.Ext(filename)
	if ext == "" {
		ext = ".bin"
	}
	objectKey := path.Join(passengerID, fmt.Sprintf("%s_%s%s", strings.ToLower(docType), uuid.New().String(), ext))

	_, err := m.client.PutObject(ctx, bucketName, objectKey, reader, size, minio.PutObjectOptions{
		ContentType: contentType,
	})
	if err != nil {
		return "", err
	}
	return objectKey, nil
}

func (m *MinIO) DeleteObject(ctx context.Context, objectKey string) error {
	return m.client.RemoveObject(ctx, bucketName, objectKey, minio.RemoveObjectOptions{})
}
