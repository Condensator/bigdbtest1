SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[CourtFilingLegalReliefs](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[LegalReliefDisplay] [nvarchar](12) COLLATE Latin1_General_CI_AS NULL,
	[IsActive] [bit] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[LegalReliefId] [bigint] NULL,
	[CourtFilingId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[CourtFilingLegalReliefs]  WITH CHECK ADD  CONSTRAINT [ECourtFiling_CourtFilingLegalReliefs] FOREIGN KEY([CourtFilingId])
REFERENCES [dbo].[CourtFilings] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[CourtFilingLegalReliefs] CHECK CONSTRAINT [ECourtFiling_CourtFilingLegalReliefs]
GO
ALTER TABLE [dbo].[CourtFilingLegalReliefs]  WITH CHECK ADD  CONSTRAINT [ECourtFilingLegalRelief_LegalRelief] FOREIGN KEY([LegalReliefId])
REFERENCES [dbo].[LegalReliefs] ([Id])
GO
ALTER TABLE [dbo].[CourtFilingLegalReliefs] CHECK CONSTRAINT [ECourtFilingLegalRelief_LegalRelief]
GO
