SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[CreditProfileOFACRequests](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[IsActive] [bit] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[OFACRequestId] [bigint] NOT NULL,
	[CreditProfileId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[CreditProfileOFACRequests]  WITH CHECK ADD  CONSTRAINT [ECreditProfile_CreditProfileOFACRequests] FOREIGN KEY([CreditProfileId])
REFERENCES [dbo].[CreditProfiles] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[CreditProfileOFACRequests] CHECK CONSTRAINT [ECreditProfile_CreditProfileOFACRequests]
GO
ALTER TABLE [dbo].[CreditProfileOFACRequests]  WITH CHECK ADD  CONSTRAINT [ECreditProfileOFACRequest_OFACRequest] FOREIGN KEY([OFACRequestId])
REFERENCES [dbo].[OFACRequests] ([Id])
GO
ALTER TABLE [dbo].[CreditProfileOFACRequests] CHECK CONSTRAINT [ECreditProfileOFACRequest_OFACRequest]
GO
