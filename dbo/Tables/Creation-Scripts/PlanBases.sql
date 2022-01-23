SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[PlanBases](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[PlanBasisNumber] [nvarchar](100) COLLATE Latin1_General_CI_AS NULL,
	[PlanBasisDescription] [nvarchar](200) COLLATE Latin1_General_CI_AS NOT NULL,
	[PlanBasisAbbreviation] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[Status] [nvarchar](8) COLLATE Latin1_General_CI_AS NULL,
	[PlanBasisQuoteDocument_Source] [nvarchar](250) COLLATE Latin1_General_CI_AS NULL,
	[PlanBasisQuoteDocument_Type] [nvarchar](5) COLLATE Latin1_General_CI_AS NULL,
	[PlanBasisQuoteDocument_Content] [varbinary](82) NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[PlanFamilyId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 80, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[PlanBases]  WITH CHECK ADD  CONSTRAINT [EPlanBase_PlanFamily] FOREIGN KEY([PlanFamilyId])
REFERENCES [dbo].[PlanFamilies] ([Id])
GO
ALTER TABLE [dbo].[PlanBases] CHECK CONSTRAINT [EPlanBase_PlanFamily]
GO
