SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[DisbursementRequestOFACHits](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[OFACHitId] [bigint] NOT NULL,
	[DisbursementRequestId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[DisbursementRequestOFACHits]  WITH CHECK ADD  CONSTRAINT [EDisbursementRequest_DisbursementRequestOFACHits] FOREIGN KEY([DisbursementRequestId])
REFERENCES [dbo].[DisbursementRequests] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[DisbursementRequestOFACHits] CHECK CONSTRAINT [EDisbursementRequest_DisbursementRequestOFACHits]
GO
ALTER TABLE [dbo].[DisbursementRequestOFACHits]  WITH CHECK ADD  CONSTRAINT [EDisbursementRequestOFACHit_OFACHit] FOREIGN KEY([OFACHitId])
REFERENCES [dbo].[OFACHits] ([Id])
GO
ALTER TABLE [dbo].[DisbursementRequestOFACHits] CHECK CONSTRAINT [EDisbursementRequestOFACHit_OFACHit]
GO
