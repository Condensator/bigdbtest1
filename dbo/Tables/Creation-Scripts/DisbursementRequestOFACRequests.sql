SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[DisbursementRequestOFACRequests](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[OFACRequestId] [bigint] NOT NULL,
	[DisbursementRequestId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[DisbursementRequestOFACRequests]  WITH CHECK ADD  CONSTRAINT [EDisbursementRequest_DisbursementRequestOFACRequests] FOREIGN KEY([DisbursementRequestId])
REFERENCES [dbo].[DisbursementRequests] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[DisbursementRequestOFACRequests] CHECK CONSTRAINT [EDisbursementRequest_DisbursementRequestOFACRequests]
GO
ALTER TABLE [dbo].[DisbursementRequestOFACRequests]  WITH CHECK ADD  CONSTRAINT [EDisbursementRequestOFACRequest_OFACRequest] FOREIGN KEY([OFACRequestId])
REFERENCES [dbo].[OFACRequests] ([Id])
GO
ALTER TABLE [dbo].[DisbursementRequestOFACRequests] CHECK CONSTRAINT [EDisbursementRequestOFACRequest_OFACRequest]
GO
