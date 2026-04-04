-- Migration: add similarity/verification columns to documents
ALTER TABLE documents
    ADD COLUMN IF NOT EXISTS verification_status VARCHAR(20) NOT NULL DEFAULT 'verified',
    ADD COLUMN IF NOT EXISTS similarity_score FLOAT,
    ADD COLUMN IF NOT EXISTS duplicate_of_id UUID REFERENCES documents(id);
 
-- Index for moderator queue: pending docs sorted by similarity
CREATE INDEX IF NOT EXISTS idx_documents_verification_status
    ON documents(verification_status, similarity_score DESC NULLS LAST);