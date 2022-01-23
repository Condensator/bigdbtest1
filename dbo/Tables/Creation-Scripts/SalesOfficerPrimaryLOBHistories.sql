SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[SalesOfficerPrimaryLOBHistories](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[EffectiveDate] [date] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[LineofBusinessId] [bigint] NOT NULL,
	[SalesOfficerId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[SalesOfficerPrimaryLOBHistories]  WITH CHECK ADD  CONSTRAINT [ESalesOfficer_SalesOfficerPrimaryLOBHistories] FOREIGN KEY([SalesOfficerId])
REFERENCES [dbo].[SalesOfficers] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[SalesOfficerPrimaryLOBHistories] CHECK CONSTRAINT [ESalesOfficer_SalesOfficerPrimaryLOBHistories]
GO
ALTER TABLE [dbo].[SalesOfficerPrimaryLOBHistories]  WITH CHECK ADD  CONSTRAINT [ESalesOfficerPrimaryLOBHistory_LineofBusiness] FOREIGN KEY([LineofBusinessId])
REFERENCES [dbo].[LineofBusinesses] ([Id])
GO
ALTER TABLE [dbo].[SalesOfficerPrimaryLOBHistories] CHECK CONSTRAINT [ESalesOfficerPrimaryLOBHistory_LineofBusiness]
GO
