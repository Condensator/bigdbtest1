SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[LegalStatusHistories](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[AssignmentDate] [date] NULL,
	[IsActive] [bit] NOT NULL,
	[SourceModule] [nvarchar](14) COLLATE Latin1_General_CI_AS NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[LegalStatusId] [bigint] NULL,
	[CustomerId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[LegalStatusHistories]  WITH CHECK ADD  CONSTRAINT [ECustomer_LegalStatusHistories] FOREIGN KEY([CustomerId])
REFERENCES [dbo].[Customers] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[LegalStatusHistories] CHECK CONSTRAINT [ECustomer_LegalStatusHistories]
GO
ALTER TABLE [dbo].[LegalStatusHistories]  WITH CHECK ADD  CONSTRAINT [ELegalStatusHistory_LegalStatus] FOREIGN KEY([LegalStatusId])
REFERENCES [dbo].[LegalStatusConfigs] ([Id])
GO
ALTER TABLE [dbo].[LegalStatusHistories] CHECK CONSTRAINT [ELegalStatusHistory_LegalStatus]
GO
